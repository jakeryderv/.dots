#!/usr/bin/env bash
# Aliases

# scratchpad
alias pad="nvim ~/.scratchpad.md"

# source ~/.bashrc easily
alias brc='echo "sourcing ~/.bashrc" && source ~/.bashrc'

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

# Keep shared Playwright CLI browser sessions separate when coding agents run
# concurrently. An explicitly supplied session name still wins.
alias codex='PLAYWRIGHT_CLI_SESSION="${PLAYWRIGHT_CLI_SESSION:-codex}" codex'
alias claude='PLAYWRIGHT_CLI_SESSION="${PLAYWRIGHT_CLI_SESSION:-claude}" claude'
alias pi='PLAYWRIGHT_CLI_SESSION="${PLAYWRIGHT_CLI_SESSION:-pi}" pi'
# OpenCode discovers both ~/.agents/skills and ~/.claude/skills by default.
# Ignore the Claude compatibility mirror so each shared skill is loaded once.
alias opencode='OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1 PLAYWRIGHT_CLI_SESSION="${PLAYWRIGHT_CLI_SESSION:-opencode}" opencode'

# color aliases
# LC_COLLATE=C = GitHub-style byte-order sorting: dotfiles first, then
# underscore-prefixed, then letters — instead of locale collation that
# interleaves punctuation-prefixed names. Scoped to ls only (sort, globs,
# and scripts keep the normal locale). All ls variants below inherit both
# behaviors by alias-expanding through this base alias.
alias ls='LC_COLLATE=C ls --color=auto --group-directories-first'
alias grep='grep --color=auto'
# fgrep/egrep are deprecated; use grep -F/-E
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'

# more ls aliases
alias ll='ls -AlF --group-directories-first'
alias la='ls -AF --group-directories-first'
alias l='ls -CF --group-directories-first'
alias lsd="shopt -s dotglob; ls -CxdF [^.]* .[^.]* 2>/dev/null"
alias lsl="shopt -s dotglob; ls -ldF [^.]* .[^.]* 2>/dev/null"

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
alias gce='git config --global --edit'

# Add all, commit, and push in one shot: gacp "your message"
gacp() { git add . && git commit -m "$1" && git push; }

# New branch + push it with upstream set: gnew feature-name
gnew() { git checkout -b "$1" && git push -u origin "$1"; }
