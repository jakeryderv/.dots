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

# Bat (Debian ships the binary as batcat; alias only if the plain name is absent)
command -v bat >/dev/null 2>&1 || alias bat='batcat'

# kitty stuff
alias icat="kitten icat"

# python venv shortcut
alias activate="source .venv/bin/activate"

# color aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
# fgrep/egrep are deprecated; use grep -F/-E
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'

# more ls aliases
alias ll='ls -AlF --group-directories-first'
alias la='ls -AF --group-directories-first'
alias l='ls -CF --group-directories-first'
alias lsd="shopt -s dotglob; ls -CxdF --color=auto --group-directories-first [^.]* .[^.]* 2>/dev/null"
alias lsl="shopt -s dotglob; ls -ldF --color=auto --group-directories-first [^.]* .[^.]* 2>/dev/null"

# alert for long running commands, e.g.  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ── Git shortcuts ──
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'

# Add all, commit, and push in one shot: gacp "your message"
gacp() { git add . && git commit -m "$1" && git push; }

# New branch + push it with upstream set: gnew feature-name
gnew() { git checkout -b "$1" && git push -u origin "$1"; }
