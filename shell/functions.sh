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

explain() {
    local url
    url=$(python3 -c 'import sys,urllib.parse; print("https://explainshell.com/explain?cmd="+urllib.parse.quote(" ".join(sys.argv[1:])))' "$@")
    xdg-open "$url" 2>/dev/null || echo "$url"
}

bashstyle() {
    local url='https://style.ysap.sh'
    local mode=${1:-auto}
    local bat=''

    # debian/ubuntu ship bat as batcat
    if hash batcat 2>/dev/null; then
        bat=batcat
    elif hash bat 2>/dev/null; then
        bat=bat
    fi

    if [[ $mode == auto ]]; then
        if [[ -n $bat ]]; then
            mode=bat
        else
            mode=less
        fi
    fi

    case "$mode" in
    bat)
        [[ -n $bat ]] || {
            echo 'bashstyle: bat/batcat not found' >&2
            return 1
        }
        curl -fsSL "$url" | "$bat" -l md --style=plain
        ;;
    less)
        curl -fsSL "$url" | less -R
        ;;
    *)
        echo 'usage: bashstyle [bat|less]' >&2
        return 1
        ;;
    esac
}

hello-colors() {
    printf '\e[31mHello, World!\e[0m\n' # Red
    printf '\e[32mHello, World!\e[0m\n' # Green
    printf '\e[34mHello, World!\e[0m\n' # Blue
}
