#!/usr/bin/env bash
# Custom keybindings

# `bind` requires an interactive shell; skip otherwise to avoid warnings.
[[ $- == *i* ]] || return 0

# Tmux-sessionizer (only bind if it's installed)
if command -v tmux-sessionizer >/dev/null 2>&1; then
	bind -x '"\C-f": tmux-sessionizer'
fi
