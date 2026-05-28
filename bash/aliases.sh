#!/bin/bash

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

# fallbask basic ls stuff
alias ls='ls --color=auto'
