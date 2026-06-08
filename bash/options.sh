#!/usr/bin/env bash
# Shell options and history

# don't put duplicate lines or lines starting with space in the history
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# history length
HISTSIZE=1000
HISTFILESIZE=2000

# check window size after each command, update LINES and COLUMNS
shopt -s checkwinsize
