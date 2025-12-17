#!/bin/bash
# Aliases

# source ~/.bashrc easily
alias brc='source ~/.bashrc'

# Nvim config
alias nvimc='nvim ~/.config/nvim'

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

# Eza
# alias l='eza --icons --group-directories-first'
# alias ls='eza --icons --group-directories-first'
# alias ll='eza -l --icons --group-directories-first --git'
# alias la='eza -la --icons --group-directories-first --git'
# alias lt='eza --tree --level=2 --icons'
# alias lg='eza -l --icons --git'

# bs - custom ls tooling
alias l='bs -nLT --icons --relative'
alias la='bs -anLT --icons --relative'
alias lw='bs -nLT --icons --relative --watch'
alias ltree='bs -R --tree --depth'

# fallbask basic ls stuff
alias ls='ls --color=auto'
