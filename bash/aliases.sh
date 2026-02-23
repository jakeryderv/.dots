#!/bin/bash

# Aliases

# scratchpad
alias pad="nvim ~/.scratchpad.md"

# windows
alias windows="cd /mnt/c/Users/jaker"
export WINHOME="/mnt/c/Users/jaker"

# source ~/.bashrc easily
alias brc='source ~/.bashrc'

# get shell level
alias shlvl='echo $SHLVL'

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

# bs - custom ls tooling
alias l='bs -nLT --icons --relative'
alias la='bs -anLT --icons --relative'
alias lw='bs -nLT --icons --relative --watch'
alias ltree='bs -R --tree --depth'

# fallbask basic ls stuff
alias ls='ls --color=auto'

# launch qutebrowser (windows install, opening links & searches from wsl terminal)
qb() {
  command -v qutebrowser.exe >/dev/null 2>&1 || {
    echo "qb: qutebrowser.exe not in PATH" >&2
    return 127
  }

  [ "$#" -gt 0 ] || {
    echo "usage: qb URL... | qb -s search terms..." >&2
    return 2
  }

  if [ "$1" = "-s" ]; then
    shift
    [ "$#" -gt 0 ] || { echo "qb: empty search query" >&2; return 2; }
    q="$*"
    q="${q// /+}"
    qutebrowser.exe "https://duckduckgo.com/?q=$q" >/dev/null 2>&1 &
    return
  fi

  for arg in "$@"; do
    qutebrowser.exe "$arg" >/dev/null 2>&1 &
  done
}

