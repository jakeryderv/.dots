#!/bin/bash
# Environment variables and exports

# Editor
if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR='vim'
else
	export EDITOR='nvim'
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Opencode
export PATH=/home/jake/.opencode/bin:$PATH

# Cargo
. "$HOME/.cargo/env"

# EZA colors (if you add them)
# export EZA_COLORS="di=1;34"
