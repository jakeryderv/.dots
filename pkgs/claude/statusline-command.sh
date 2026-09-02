#!/usr/bin/env bash
# Claude Code status line — two-line left/right split layout
input=$(cat)

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
# ANSI-C quoting ($'...') stores real escape bytes, so output can be printed
# with %s. Never use %b: it would also expand backslash sequences in branch
# and session names.
BOLD=$'\033[1m'
NODIM=$'\033[22m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
GRAY=$'\033[90m'

# ---------------------------------------------------------------------------
# Parse ALL JSON fields in a single jq call
#
# Declared up front because the eval below is the only assignment, and
# ShellCheck cannot see through eval -- without these it reports SC2154 at
# every use site. Initialising also means a failed jq leaves these empty
# rather than inheriting whatever happened to be exported.
# ---------------------------------------------------------------------------
model_id='' session_name='' output_style='' cwd='' project_dir=''
wt_name='' vim_mode='' ctx_total=0 ctx_used_pct=''

eval "$(echo "$input" | jq -r '
  def esc: gsub("[\n\r]"; " ") | gsub("'\''"; "'\''\\'\'''\''");
  "model_id='\''\(.model.id // "" | esc)'\''",
  "session_name='\''\(.session_name // "" | esc)'\''",
  "output_style='\''\(.output_style.name // "" | esc)'\''",
  "cwd='\''\(.workspace.current_dir // .cwd // "" | esc)'\''",
  "project_dir='\''\(.workspace.project_dir // "" | esc)'\''",
  "wt_name='\''\(.worktree.name // "" | esc)'\''",
  "vim_mode='\''\(.vim.mode // "" | esc)'\''",
  "ctx_total=\(.context_window.context_window_size // 0)",
  "ctx_used_pct=\(.context_window.used_percentage // "\"\"")"
')"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

fmt_k() {
    local n="$1"
    [[ -z "$n" || "$n" == "null" ]] && {
        echo "0"
        return
    }
    awk -v n="$n" 'BEGIN {
    if (n >= 1000) {
      s = sprintf("%.1f", n/1000); sub(/\.0$/, "", s); print s "k"
    } else print n
  }'
}

# Unicode progress bar: █ for filled, ░ for empty
make_bar() {
    local pct="$1" width=10
    local filled=$((pct * width / 100))
    ((filled > width)) && filled=$width
    local empty=$((width - filled))
    local bar=""
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf '%s' "$bar"
}

# Print a line — no right-padding; Ink's flex layout handles positioning
print_line() {
    printf '%s\n' "$1"
}

# Ink wraps all output in dimColor, so undecorated text is already dim.
# Use NODIM or color codes to make text stand out.
SEP=" │ "

# ---------------------------------------------------------------------------
# LINE 1 — LEFT
# ---------------------------------------------------------------------------

# Short model name
if [ -n "$model_id" ]; then
    short_model="${model_id#claude-}"
    # Drop a bracketed variant (e.g. "[1m]") — the context bar on line 2 already
    # shows the window size.
    short_model="${short_model%%\[*}"
    # Drop a trailing release date, then dot the version: a dash between two
    # digits becomes a dot ("opus-4-8" -> "opus-4.8"), while the name/version
    # dash is left alone ("opus-5" stays "opus-5").
    short_model=$(echo "$short_model" | sed -E 's/-[0-9]{8}$//; :a; s/([0-9])-([0-9])/\1.\2/; ta')
else
    short_model="unknown"
fi

# Git branch + colored status
git_info=""
if [ -n "$cwd" ] && cd "$cwd" 2>/dev/null; then
    branch=$(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git symbolic-ref --short HEAD 2>/dev/null ||
        GIT_OPTIONAL_LOCKS=0 timeout 0.5 git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        added=0 modified=0 deleted=0 untracked=0
        while IFS= read -r line; do
            xy="${line:0:2}"
            idx="${xy:0:1}"
            wt_c="${xy:1:1}"
            if [[ "$idx" == "?" && "$wt_c" == "?" ]]; then
                ((untracked++))
                continue
            fi
            [[ "$idx" == "A" ]] && ((added++))
            # R/C (staged rename/copy) count as modified — one test, so a
            # combined status like "RM" counts the file once.
            [[ "$idx" == "M" || "$idx" == "R" || "$idx" == "C" || "$wt_c" == "M" ]] && ((modified++))
            [[ "$idx" == "D" || "$wt_c" == "D" ]] && ((deleted++))
        done < <(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git status --porcelain 2>/dev/null)

        # One call for both counts: "behind<TAB>ahead". With no upstream git
        # errors out, so both stay empty and the guards below skip them.
        behind="" ahead=""
        read -r behind ahead < <(GIT_OPTIONAL_LOCKS=0 timeout 0.5 \
            git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)

        stash=$(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git stash list 2>/dev/null | wc -l)

        # In-progress operation. The state lives in the git dir, which is a
        # *file* in a linked worktree — so ask git instead of testing
        # "$cwd/.git". Exact paths only: a leftover rerere MERGE_RR must not
        # read as an in-progress merge.
        gitdir=$(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git rev-parse --git-dir 2>/dev/null)
        op=""
        if [ -n "$gitdir" ]; then
            if [ -d "$gitdir/rebase-merge" ]; then
                op="REBASE"
            elif [ -d "$gitdir/rebase-apply" ]; then
                # rebase-apply backs both "rebase --apply" and "git am".
                if [ -f "$gitdir/rebase-apply/applying" ]; then op="AM"; else op="REBASE"; fi
            elif [ -f "$gitdir/MERGE_HEAD" ]; then
                op="MERGE"
            elif [ -f "$gitdir/CHERRY_PICK_HEAD" ]; then
                op="CHERRY-PICK"
            elif [ -f "$gitdir/REVERT_HEAD" ]; then
                op="REVERT"
            elif [ -f "$gitdir/BISECT_LOG" ]; then
                op="BISECT"
            fi
        fi

        git_info="${CYAN}${branch}${RESET}"
        [ -n "$op" ] && git_info="${git_info} ${MAGENTA}${op}${RESET}"
        [[ -n "$ahead" && "$ahead" -gt 0 ]] && git_info="${git_info} ${CYAN}↑${ahead}${RESET}"
        [[ -n "$behind" && "$behind" -gt 0 ]] && git_info="${git_info} ${CYAN}↓${behind}${RESET}"
        ((added > 0)) && git_info="${git_info} ${GREEN}+${added}${RESET}"
        ((modified > 0)) && git_info="${git_info} ${YELLOW}~${modified}${RESET}"
        ((deleted > 0)) && git_info="${git_info} ${RED}-${deleted}${RESET}"
        ((untracked > 0)) && git_info="${git_info} ${GRAY}?${untracked}${RESET}"
        ((stash > 0)) && git_info="${git_info} ${YELLOW}*${stash}${RESET}"
    fi
fi

# Directory display — project-relative, with the middle elided so that a deep
# path stays about as short as a bare basename. "6.1.1" or "memory" alone says
# nothing; ".claude/…/6.1.1" says where you are.
dir_display=""
if [ -n "$cwd" ]; then
    if [ -z "$project_dir" ] || [ "$cwd" = "$project_dir" ]; then
        # At the project root, or no project context: just the name.
        dir_display=${cwd##*/}
    elif [[ "$cwd" == "$project_dir"/* ]]; then
        rel=${cwd#"$project_dir"/}
        if [[ "$rel" == */*/* ]]; then
            # 3+ components: keep the first and last, elide the middle.
            dir_display="${rel%%/*}/…/${rel##*/}"
        else
            dir_display="$rel"
        fi
    else
        # Outside the project root (/add-dir, symlink): basename only.
        dir_display=${cwd##*/}
    fi
    # cwd of "/" (or a trailing slash) leaves the expansion empty.
    [ -z "$dir_display" ] && dir_display="/"
fi

# i-have-adhd always-on flag. The plugin's SessionStart hook injects its ruleset
# only while this file exists, and resolves the config dir the same way — so the
# indicator tracks the hook rather than guessing. Says nothing about a per-session
# /i-have-adhd or "stop adhd mode": neither leaves any on-disk state to read.
adhd_flag=""
if [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.i-have-adhd-always" ]; then
    adhd_flag="${MAGENTA}adhd${RESET}"
fi

line1_left="${BOLD}${short_model}${RESET}"
[ -n "$git_info" ] && line1_left="${line1_left}${SEP}${git_info}"
[ -n "$dir_display" ] && line1_left="${line1_left}${SEP}${dir_display}"
[ -n "$wt_name" ] && line1_left="${line1_left}${SEP}wt:${wt_name}"
[ -n "$session_name" ] && line1_left="${line1_left}${SEP}${session_name}"
[ -n "$output_style" ] && [ "$output_style" != "default" ] && line1_left="${line1_left}${SEP}${output_style}"
[ -n "$adhd_flag" ] && line1_left="${line1_left}${SEP}${adhd_flag}"

# ---------------------------------------------------------------------------
# LINE 2 — LEFT  (context bar)
# ---------------------------------------------------------------------------

if [ -n "$ctx_used_pct" ]; then
    used_int=$(printf "%.0f" "$ctx_used_pct")
    bar=$(make_bar "$used_int")
    tokens_used=$(awk -v t="$ctx_total" -v p="$ctx_used_pct" 'BEGIN { printf "%.0f", t*p/100 }')
    # Color bar based on usage
    if ((used_int >= 80)); then
        bar_color="$RED"
    elif ((used_int >= 50)); then
        bar_color="$YELLOW"
    else
        bar_color="$GREEN"
    fi
    line2_left="${bar_color}${bar}${RESET} ${NODIM}${used_int}%${RESET} ($(fmt_k "$tokens_used")/$(fmt_k "$ctx_total"))"
else
    line2_left="░░░░░░░░░░ --% (--/$(fmt_k "$ctx_total"))"
fi

# ---------------------------------------------------------------------------
# Output — left-aligned only; Ink's flexbox handles right-side built-in widgets
# ---------------------------------------------------------------------------

# Append vim mode to line 2 if present
[ -n "$vim_mode" ] && line2_left="${line2_left}${SEP}${vim_mode}"

print_line "$line1_left"
print_line "$line2_left"
