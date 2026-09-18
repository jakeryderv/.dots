# shellcheck shell=bash
# Shell functions, written to run under bash and zsh alike.

# mkcd <dir> - create a directory and cd into it
mkcd() {
    [[ "$1" == "-h" ]] && echo "Usage: mkcd <directory>" && return
    [[ -z "$1" ]] && echo "Error: provide a directory name" && return 1
    mkdir -p "$1" && cd "$1" || return 1
}

# up [N] - go up N directories from cwd (default 1)
up() {
    local count="${1:-1}"
    if ! [[ "$count" =~ ^[0-9]+$ ]]; then
        echo "up: argument must be a positive number" >&2
        return 1
    fi
    # Not `path`: zsh ties that name to PATH, and a local scalar of it would
    # clobber the search path for the cd below.
    local target=""
    for ((i = 0; i < count; i++)); do
        target+="../"
    done
    cd "$target" || return 1
}

daily() {
    local dir
    local readme
    local today

    today="$(date +%F)"
    dir="$HOME/daily-dev/log/$today"
    readme="$dir/README.md"

    mkdir -p "$dir"

    if [[ ! -f "$readme" ]]; then
        cat >"$readme" <<EOF
---
date: $today
tags: []
projects: []
---

# $today

## Worked On

## Notes
EOF
    fi

    cd "$dir" || return
    "${EDITOR:-nvim}" README.md
}
