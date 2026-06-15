#!/usr/bin/env bash
# Aliases

# scratchpad
alias pad="nvim ~/.scratchpad.md"

# source ~/.bashrc easily
alias brc='source ~/.bashrc'

# get shell level
alias shlvl='echo $SHLVL'

# FZF
alias ff='nvim $(fzf --preview "cat {}")'
alias fcd='cd $(fdfind --type d | fzf)'

# Tmux
alias tmls='tmux ls'
alias tma='tmux attach -t $(tmux ls -F "#{session_name}" | fzf)'
tms() {
    tmux new-session -A -s "$1"
}
alias tmks='tmux list-sessions | fzf | cut -d: -f1 | xargs tmux kill-session -t'
alias tmka='tmux kill-server'

# Bat
alias bat='batcat'

# kitty stuff
alias icat="kitten icat"

# python venv shortcut
alias activate="source .venv/bin/activate"

# color aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# more ls aliases
alias ll='ls -AlF --group-directories-first'
alias la='ls -AF --group-directories-first'
alias l='ls -CF --group-directories-first'
alias lsd="shopt -s dotglob; ls -CxdF --color=auto --group-directories-first [^.]* .[^.]* 2>/dev/null"

# alert for long running commands, e.g.  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
