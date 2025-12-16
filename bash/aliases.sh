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
alias tks='tmux list-sessions | fzf | cut -d: -f1 | xargs tmux kill-session -t'
alias tkill='tmux kill-server'
alias tls='tmux ls'
alias tma='tmux attach -t $(tmux ls -F "#{session_name}" | fzf)'

# Bat
alias bat='batcat'

# Eza
alias l='eza --icons --group-directories-first'
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias lg='eza -l --icons --git'
