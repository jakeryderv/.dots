#!/usr/bin/env bash
# Environment variables and exports

# Path (guard against duplication when sourced from non-login subshells)
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# ls colors (LS_COLORS)
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Editor
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# Tool telemetry opt-out. OpenSpec has no config-file switch — it checks
# OPENSPEC_TELEMETRY === '0' (and the cross-tool DO_NOT_TRACK === '1').
export OPENSPEC_TELEMETRY=0

# man stuff
if command -v nvim >/dev/null 2>&1; then
    export MANPAGER='nvim +Man!'
elif command -v vim >/dev/null 2>&1; then
    export MANPAGER='vim -M -c "runtime! ftplugin/man.vim" -c MANPAGER -'
else
    export LESS='-R'
    export LESS_TERMCAP_md=$'\e[1;36m'
    export LESS_TERMCAP_us=$'\e[1;32m'
    export LESS_TERMCAP_so=$'\e[1;44;37m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_ue=$'\e[0m'
    export LESS_TERMCAP_se=$'\e[0m'
fi
