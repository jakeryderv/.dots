#!/usr/bin/env bash
# Claude Code status line — two-line left/right split layout
input=$(cat)

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
BOLD='\033[1m'
NODIM='\033[22m'
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
GRAY='\033[90m'

# ---------------------------------------------------------------------------
# Parse ALL JSON fields in a single jq call
# ---------------------------------------------------------------------------
eval "$(echo "$input" | jq -r '
  def esc: gsub("'\''"; "'\''\\'\'''\''");
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
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    printf '%s' "$bar"
}

# Print a line — no right-padding; Ink's flex layout handles positioning
print_line() {
    printf "%b\n" "$1"
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
    short_model=$(echo "$short_model" | sed 's/-\([0-9]\+\)$/.\1/')
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
            [[ "$idx" == "M" || "$wt_c" == "M" ]] && ((modified++))
            [[ "$idx" == "D" || "$wt_c" == "D" ]] && ((deleted++))
        done < <(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git status --porcelain 2>/dev/null)

        ahead=$(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git rev-list --count @{u}..HEAD 2>/dev/null)
        stash=$(GIT_OPTIONAL_LOCKS=0 timeout 0.5 git stash list 2>/dev/null | wc -l)

        git_info="${CYAN}${branch}${RESET}"
        [[ -n "$ahead" && "$ahead" -gt 0 ]] && git_info="${git_info} ${CYAN}↑${ahead}${RESET}"
        ((added > 0)) && git_info="${git_info} ${GREEN}+${added}${RESET}"
        ((modified > 0)) && git_info="${git_info} ${YELLOW}~${modified}${RESET}"
        ((deleted > 0)) && git_info="${git_info} ${RED}-${deleted}${RESET}"
        ((untracked > 0)) && git_info="${git_info} ${GRAY}?${untracked}${RESET}"
        ((stash > 0)) && git_info="${git_info} ${YELLOW}*${stash}${RESET}"
    fi
fi

# Directory display
dir_display=""
if [ -n "$cwd" ]; then
    if [ -n "$project_dir" ] && [ "$cwd" != "$project_dir" ]; then
        dir_display=$(basename "${cwd#"$project_dir"/}")
    else
        dir_display=$(basename "$cwd")
    fi
fi

line1_left="${BOLD}${short_model}${RESET}"
[ -n "$git_info" ] && line1_left="${line1_left}${SEP}${git_info}"
[ -n "$dir_display" ] && line1_left="${line1_left}${SEP}${dir_display}"
[ -n "$wt_name" ] && line1_left="${line1_left}${SEP}wt:${wt_name}"
[ -n "$session_name" ] && line1_left="${line1_left}${SEP}${session_name}"
[ -n "$output_style" ] && [ "$output_style" != "default" ] && line1_left="${line1_left}${SEP}${output_style}"

# Caveman mode badge
cvm_flag="$HOME/.claude/.caveman-active"
if [ -f "$cvm_flag" ]; then
    cvm_mode=$(cat "$cvm_flag" 2>/dev/null)
    ORANGE='\033[38;5;172m'
    if [ "$cvm_mode" = "full" ] || [ -z "$cvm_mode" ]; then
        cvm_badge="${ORANGE}[CAVEMAN]${RESET}"
    else
        cvm_suffix=$(echo "$cvm_mode" | tr '[:lower:]' '[:upper:]')
        cvm_badge="${ORANGE}[CAVEMAN:${cvm_suffix}]${RESET}"
    fi
    line1_left="${line1_left}${SEP}${cvm_badge}"
fi

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
