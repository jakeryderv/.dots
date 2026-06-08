#!/usr/bin/env bash
# Bash completion configuration

# Load bash-completion (modern path, legacy fallback)
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Tab cycles through completions
bind '"\t": menu-complete'
bind '"\e[Z": menu-complete-backward'

# Case-insensitive completion
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set menu-complete-display-prefix on"
bind "set mark-directories on"
bind "set colored-stats on"
bind "set colored-completion-prefix on"
bind "set completion-map-case on"

# Better history search
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
