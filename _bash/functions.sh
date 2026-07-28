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

# ---- git config helper -------------------------------------------------
# usage: gconf [scope] [action]
gconf() {
    local scope action

    # bare `gconf` → merged view of every scope, labeled
    if (($# == 0)); then
        git config --list --show-scope
        return
    fi

    case "$1" in
    h | -h | --help | help)
        printf 'usage: gconf [scope] [action]\n'
        printf '  scope:  l|local   g|global   s|system\n'
        printf '  action: l|list (default)   e|edit   o|origin\n'
        printf '  origin = list annotated with the file each value came from\n'
        printf '  bare `gconf` lists all scopes merged\n'
        return 0
        ;;
    l | local) scope=--local ;;
    g | global) scope=--global ;;
    s | system) scope=--system ;;
    *)
        printf 'gconf: unknown scope %q (want: local|global|system)\n' "$1" >&2
        return 2
        ;;
    esac

    case "${2:-list}" in
    l | ls | list) action=list ;;
    e | edit) action=edit ;;
    o | origin | where) action=origin ;;
    *)
        printf 'gconf: unknown action %q (want: list|edit|origin)\n' "$2" >&2
        return 2
        ;;
    esac

    case $action in
    list) git config "$scope" --list ;;
    edit) git config "$scope" --edit ;;
    origin) git config "$scope" --list --show-origin ;;
    esac
}

# position-aware tab completion
_gconf() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    case $COMP_CWORD in
    1) COMPREPLY=($(compgen -W 'local global system help' -- "$cur")) ;;
    2) COMPREPLY=($(compgen -W 'list edit origin' -- "$cur")) ;;
    *) COMPREPLY=() ;;
    esac
}
complete -F _gconf gconf
# ------------------------------------------------------------------------
