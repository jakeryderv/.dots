#!/bin/bash
# Custom functions

# Add functions here as you create them
# lss() { ... }

## mkcd <dir> - Create directory and cd into it
function mkcd() {
    [[ "$1" == "-h" ]] && echo "Usage: mkcd <directory>" && return
    [[ -z "$1" ]] && echo "Error: provide a directory name" && return 1
    mkdir -p "$1" && cd "$1" || return 1
}
