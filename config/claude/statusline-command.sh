#!/usr/bin/env bash
# Claude Code status line — two lines, left-aligned.
#   1: model │ git │ dir │ wt │ session │ output style │ adhd
#   2: context bar │ rate limits │ vim mode
# Input schema: https://code.claude.com/docs/en/statusline#available-data
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

# Ink wraps all output in dimColor, so undecorated text is already dim.
# Use NODIM or color codes to make text stand out.
SEP=" │ "

# ---------------------------------------------------------------------------
# Parse every field, and do the number formatting, in a single jq call
#
# Declared up front because the eval below is the only assignment, and
# ShellCheck cannot see through eval -- without these it reports SC2154 at
# every use site. Initialising also means a failed jq leaves these empty
# rather than inheriting whatever happened to be exported.
#
# Strings are emitted single-quoted for eval: esc turns newlines into spaces
# and ' into '\''. Numbers are emitted bare, or empty when the field is absent.
# ---------------------------------------------------------------------------
model='' session_name='' output_style='' cwd='' project_dir='' wt_name=''
vim_mode='' ctx_pct='' ctx_used_k='' ctx_total_k='' rl_5h='' rl_7d=''

read -r -d '' jq_program <<'JQ'
def esc: gsub("[\n\r]"; " ") | gsub("'"; "'\\''");
def str(f): "'\(f // "" | esc)'";
def pct: if . == null then "" else (round | tostring) end;
# 950 -> 950, 84600 -> 84.6k, 200000 -> 200k, 1000000 -> 1M
def k:
  if . >= 1000000 then "\((. / 100000 | round) / 10)M"
  elif . >= 1000 then "\((. / 100 | round) / 10)k"
  else "\(round)" end;

(.context_window.context_window_size // 0) as $total
| .context_window.used_percentage as $used
| "model=\(str(.model.display_name // .model.id // "" | sub(" *\\(.*\\)$"; "")))",
  "session_name=\(str(.session_name))",
  "output_style=\(str(.output_style.name))",
  "cwd=\(str(.workspace.current_dir // .cwd))",
  "project_dir=\(str(.workspace.project_dir))",
  "wt_name=\(str(.worktree.name))",
  "vim_mode=\(str(.vim.mode))",
  "ctx_pct=\($used | pct)",
  "ctx_used_k=\(if $used == null then "--" else ($total * $used / 100 | k) end)",
  "ctx_total_k=\($total | k)",
  "rl_5h=\(.rate_limits.five_hour.used_percentage | pct)",
  "rl_7d=\(.rate_limits.seven_day.used_percentage | pct)"
JQ
eval "$(jq -r "$jq_program" <<<"$input")"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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

# Visible width of a string: strip the SGR escapes, count characters.
shopt -s extglob
visible_width() {
    local plain=${1//$'\033['*([0-9;])m/}
    printf '%d' "${#plain}"
}

# ---------------------------------------------------------------------------
# LINE 1
# ---------------------------------------------------------------------------

[ -z "$model" ] && model="unknown"

# Git branch + colored status, from one `git status` call. Porcelain v2 with
# --branch and --show-stash (git >= 2.35) prints headers for the branch,
# ahead/behind and stash count before the file entries:
#   # branch.oid <sha> | (initial)    # branch.head <name> | (detached)
#   # branch.ab +<ahead> -<behind>    # stash <n>
#   1 XY ... (changed)  2 XY ... (renamed/copied)  u XY ... (unmerged)  ? path
# XY is the index and worktree status, with "." for unchanged.
git_info=""
if [ -n "$cwd" ] && cd "$cwd" 2>/dev/null; then
    branch="" oid="" ahead=0 behind=0 stash=0
    added=0 modified=0 deleted=0 untracked=0
    while IFS= read -r line; do
        case $line in
        '# branch.oid '*) oid=${line#\# branch.oid } ;;
        '# branch.head '*) branch=${line#\# branch.head } ;;
        '# branch.ab '*)
            read -r _ _ ahead behind <<<"$line"
            ahead=${ahead#+} behind=${behind#-}
            ;;
        '# stash '*) stash=${line#\# stash } ;;
        '? '*) ((untracked++)) ;;
        [12u]' '*)
            idx=${line:2:1} wt_c=${line:3:1}
            [[ "$idx" == "A" ]] && ((added++))
            # R/C (staged rename/copy) count as modified — one test, so a
            # combined status like "RM" counts the file once.
            [[ "$idx" == [MRC] || "$wt_c" == "M" ]] && ((modified++))
            [[ "$idx" == "D" || "$wt_c" == "D" ]] && ((deleted++))
            ;;
        esac
    done < <(GIT_OPTIONAL_LOCKS=0 timeout 0.5 \
        git status --porcelain=v2 --branch --show-stash 2>/dev/null)

    # Detached HEAD: show the short commit instead.
    [[ "$branch" == "(detached)" ]] && branch=${oid:0:7}

    if [ -n "$branch" ]; then
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
        ((ahead > 0)) && git_info="${git_info} ${CYAN}↑${ahead}${RESET}"
        ((behind > 0)) && git_info="${git_info} ${CYAN}↓${behind}${RESET}"
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

# Everything on line 1 except the session name, which goes in the middle and
# is the one segment trimmed to fit.
line1_head="${BOLD}${model}${RESET}"
[ -n "$git_info" ] && line1_head="${line1_head}${SEP}${git_info}"
[ -n "$dir_display" ] && line1_head="${line1_head}${SEP}${dir_display}"
[ -n "$wt_name" ] && line1_head="${line1_head}${SEP}wt:${wt_name}"
line1_tail=""
[ -n "$output_style" ] && [ "$output_style" != "default" ] && line1_tail="${line1_tail}${SEP}${output_style}"
[ -n "$adhd_flag" ] && line1_tail="${line1_tail}${SEP}${adhd_flag}"

# session_name falls back to the AI-generated session title, so it is nearly
# always set and can be long. Claude Code exports COLUMNS for the script (tput
# cannot see the terminal); trim the name to the room left, with a few columns
# of slack for Ink's own padding. Too little room and it is dropped. With no
# COLUMNS, it is shown whole.
if [ -n "$session_name" ] && ((${COLUMNS:-0} > 0)); then
    room=$((COLUMNS - 4 - $(visible_width "${line1_head}${line1_tail}") - ${#SEP}))
    if ((room < 8)); then
        session_name=""
    elif ((${#session_name} > room)); then
        session_name="${session_name:0:room-1}…"
    fi
fi
line1="$line1_head"
[ -n "$session_name" ] && line1="${line1}${SEP}${session_name}"
line1="${line1}${line1_tail}"

# ---------------------------------------------------------------------------
# LINE 2
# ---------------------------------------------------------------------------

# Context bar: green < 50% ≤ yellow < 80% ≤ red.
if [ -n "$ctx_pct" ]; then
    if ((ctx_pct >= 80)); then
        bar_color="$RED"
    elif ((ctx_pct >= 50)); then
        bar_color="$YELLOW"
    else
        bar_color="$GREEN"
    fi
    line2="${bar_color}$(make_bar "$ctx_pct")${RESET} ${NODIM}${ctx_pct}%${RESET} (${ctx_used_k}/${ctx_total_k})"
else
    line2="░░░░░░░░░░ --% (--/${ctx_total_k})"
fi

# Plan rate limits (Pro/Max only, and only after the first response). Each
# window may be absent on its own. Plain (dim) while low; yellow from 50%,
# red from 80%, the same thresholds as the context bar.
rate_segment() {
    local label="$1" pct="$2" color=""
    ((pct >= 80)) && color="$RED"
    ((pct >= 50 && pct < 80)) && color="$YELLOW"
    printf '%s' "${label} ${color}${pct}%${color:+$RESET}"
}
rates=""
[ -n "$rl_5h" ] && rates=$(rate_segment 5h "$rl_5h")
[ -n "$rl_7d" ] && rates="${rates:+$rates · }$(rate_segment 7d "$rl_7d")"
[ -n "$rates" ] && line2="${line2}${SEP}${rates}"

[ -n "$vim_mode" ] && line2="${line2}${SEP}${vim_mode}"

printf '%s\n' "$line1" "$line2"
