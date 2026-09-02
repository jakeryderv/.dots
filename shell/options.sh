#!/usr/bin/env bash
# Shell options and history

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# History length. The stock Ubuntu 1000/2000 was truncating: ~/.bash_history
# sat at exactly HISTFILESIZE, dropping the oldest line on every write.
HISTSIZE=100000
HISTFILESIZE=200000

# Append this shell's new commands to the file as they run, rather than only at
# exit -- with many tmux/herdr panes open, the last shell to close would
# otherwise overwrite what the others recorded. `history -a` only flushes; it
# does not re-read, so panes keep their own recall instead of interleaving.
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# check window size after each command, update LINES and COLUMNS
shopt -s checkwinsize
