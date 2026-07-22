#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHEATSHEET="$REPO_ROOT/scripts/.local/bin/tmux-cheatsheet"

[[ -x $CHEATSHEET ]] || {
    printf 'FAIL: tmux-cheatsheet is not executable\n' >&2
    exit 1
}

# shellcheck source=../../scripts/.local/bin/tmux-cheatsheet
source "$CHEATSHEET"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

tmux() {
    local table

    if [[ ${FAKE_TMUX_OFFLINE:-0} == 1 ]]; then
        return 1
    fi

    if [[ $1 == show-option ]]; then
        printf '%s\n' 'M-a'
        return
    fi

    [[ $1 == list-keys ]] || return 1
    table=${!#}
    [[ $table != missing ]] || return 1

    if [[ " $* " == *' -N '* ]]; then
        case "$table" in
        prefix)
            printf '%s\n' \
                '#       List all paste buffers' \
                '$       Rename current session' \
                ';       Move to the previously active pane' \
                'C-a     Short key' \
                'C-ab    Long key' \
                'C-\     Previous pane' \
                '%       Split window horizontally' \
                '!       Break pane to a new window' \
                'c       Create a new window' \
                'F       run-shell -b /plugins/tmux-fzf/main.sh' \
                'C-s     run-shell /plugins/tmux-resurrect/scripts/save.sh' \
                'r       Enter sticky resize mode'
            ;;
        copy-mode-vi)
            printf '%s\n' \
                'f       send-keys -X jump-forward' \
                't       send-keys -X jump-to-forward' \
                ';       send-keys -X jump-again' \
                'z       send-keys -X scroll-middle'
            ;;
        esac
        return
    fi

    case "$table" in
    prefix)
        printf '%s\n' \
            'bind-key -T prefix \# list-buffers' \
            'bind-key -T prefix \$ command-prompt -I "#S" { rename-session "%%" }' \
            'bind-key -T prefix \; last-pane' \
            'bind-key -T prefix C-a display-message short' \
            'bind-key -T prefix C-ab display-message long' \
            'bind-key -T prefix C-\\ select-pane -l' \
            'bind-key -T prefix \% split-window -h' \
            'bind-key -T prefix ! break-pane' \
            'bind-key -T prefix c new-window' \
            'bind-key -T prefix F run-shell -b /plugins/tmux-fzf/main.sh' \
            'bind-key -T prefix C-s run-shell /plugins/tmux-resurrect/scripts/save.sh' \
            'bind-key -T prefix r switch-client -T resize-mode'
        ;;
    copy-mode-vi)
        printf '%s\n' \
            'bind-key -T copy-mode-vi f send-keys -X jump-forward' \
            'bind-key -T copy-mode-vi t send-keys -X jump-to-forward' \
            'bind-key -T copy-mode-vi \; send-keys -X jump-again' \
            'bind-key -T copy-mode-vi z send-keys -X scroll-middle'
        ;;
    root | resize-mode) return 1 ;;
    *) return 1 ;;
    esac
}

rows="$(binding_rows prefix)"
[[ "$rows" == *$'#\tList all paste buffers\tlist-buffers'* ]] || fail 'escaped # key was not parsed'
[[ "$rows" == *$'$\tRename current session\tcommand-prompt'* ]] || fail 'escaped $ key was not parsed'
[[ "$rows" == *$';\tMove to the previously active pane\tlast-pane'* ]] || fail 'escaped ; key was not parsed'
[[ "$rows" == *$'C-\\\tPrevious pane\tselect-pane -l'* ]] || fail 'escaped backslash key was not parsed'
[[ "$rows" == *$'C-a\tShort key\tdisplay-message short'* ]] || fail 'short shared-prefix key was not parsed'
[[ "$rows" == *$'C-ab\tLong key\tdisplay-message long'* ]] || fail 'long shared-prefix key was not parsed'
[[ -z $(binding_rows missing) ]] || fail 'missing key table should be skipped'

[[ $(describe_binding 'send-keys -X jump-forward') == 'Jump forward to character' ]] || fail 'jump-forward label is unclear'
[[ $(describe_binding 'send-keys -X jump-to-forward') == 'Jump forward before character' ]] || fail 'jump-to-forward label is unclear'
[[ $(describe_binding 'send-keys -X jump-again') == 'Repeat last character jump' ]] || fail 'jump-again label is unclear'
[[ $(describe_binding 'send-keys -X scroll-middle') == 'Center current line' ]] || fail 'scroll-middle label is unclear'

[[ $(classify_binding 'Split window horizontally' 'Split window horizontally' 'split-window -h') == panes ]] || fail 'split-window should be grouped with panes'
[[ $(classify_binding 'Break pane to a new window' 'Break pane to a new window' 'break-pane') == panes ]] || fail 'break-pane should be grouped with panes'
[[ $(classify_binding 'Create a new window' 'Create a new window' 'new-window') == windows ]] || fail 'new-window should be grouped with windows'
[[ $(classify_binding 'raw plugin command' 'Open tmux-fzf manager' 'run-shell -b /plugins/tmux-fzf/main.sh') == plugins ]] || fail 'tmux-fzf should be grouped with plugins'
[[ $(classify_binding 'save' 'Resurrect: save tmux environment' 'run-shell /plugins/tmux-resurrect/scripts/save.sh') == sessions ]] || fail 'resurrect should be grouped with sessions'
[[ $(classify_binding 'Enter sticky resize mode' 'Enter sticky resize mode' 'switch-client -T resize-mode') == other ]] || fail 'custom key-table switch should not be grouped with sessions'

plain="$(main --plain)"
[[ "$plain" != *$'\033['* ]] || fail '--plain emitted ANSI escapes'
[[ "$plain" == *'Run with --pick for interactive filtering.'* ]] || fail 'plain output has incorrect interaction help'
pane_section="$(awk '/PANES$/ { printing = 1; next } /PLUGINS & TOOLS$/ { printing = 0 } printing' <<<"$plain")"
[[ "$pane_section" == *$'    %'* ]] || fail 'default split binding was not printed in the pane group'
session_section="$(awk '/SESSIONS & CLIENTS$/ { printing = 1; next } /WINDOWS & LAYOUTS$/ { printing = 0 } printing' <<<"$plain")"
[[ "$session_section" == *$'    $'* ]] || fail 'session command wrapped by command-prompt was misgrouped'
window_section="$(awk '/WINDOWS & LAYOUTS$/ { printing = 1; next } /PANES$/ { printing = 0 } printing' <<<"$plain")"
[[ "$window_section" == *$'    c'* ]] || fail 'window command was misgrouped'

no_color="$(NO_COLOR=1 main)"
[[ "$no_color" != *$'\033['* ]] || fail 'NO_COLOR emitted ANSI escapes'

set +e
offline="$(FAKE_TMUX_OFFLINE=1 main --plain 2>&1)"
offline_rc=$?
set -e
[[ $offline_rc == 1 ]] || fail "offline server returned $offline_rc instead of 1"
[[ "$offline" == *'cannot connect to a running tmux server'* ]] || fail 'offline server error was not actionable'

fzf() {
    printf 'fzf args: %s\n' "$*" >&2
    while IFS= read -r _; do :; done
}

picker="$(main --pick --no-color 2>&1)"
[[ "$picker" == *'--header-lines=4'* ]] || fail 'picker does not own the fixed-header configuration'
[[ "$picker" == *'enter:ignore,ctrl-u:clear-query'* ]] || fail 'picker does not own the interaction bindings'

echo 'tmux-cheatsheet tests passed'
