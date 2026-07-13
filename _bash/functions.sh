#!/usr/bin/env bash
# Custom functions

# Add functions here as you create them
# lss() { ... }

## mkcd <dir> - Create directory and cd into it
function mkcd() {
    [[ "$1" == "-h" ]] && echo "Usage: mkcd <directory>" && return
    [[ -z "$1" ]] && echo "Error: provide a directory name" && return 1
    mkdir -p "$1" && cd "$1" || return 1
}

## oc - Launch opencode with tmux-pane plugin defaults
function oc() {
    local port="${OPENCODE_PORT:-4096}"
    OPENCODE_PORT="$port" \
    OPENCODE_TMUX_LAYOUT="${OPENCODE_TMUX_LAYOUT:-main-vertical}" \
    OPENCODE_TMUX_MAIN_PANE_SIZE="${OPENCODE_TMUX_MAIN_PANE_SIZE:-60}" \
    OPENCODE_TMUX_AUTO_CLOSE="${OPENCODE_TMUX_AUTO_CLOSE:-1}" \
    opencode --port "$port" "$@"
}
