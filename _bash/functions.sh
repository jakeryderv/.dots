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

# up [N] - go up N dirs from cwd (default=1)
up() {
    local count="${1:-1}"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        echo "up: argument must be a positive number" >&2
        return 1
    fi
    local path=""
    for ((i = 0; i < count; i++)); do
        path+="../"
    done
    cd "$path" || return 1
}
