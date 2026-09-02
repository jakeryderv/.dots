#!/usr/bin/env bash
# Shell integrations for tools that flake.nix guarantees.
#
# These used to live in local.sh, back when the repo could not assume any of
# them existed. flake.nix declares all three now, so they are a property of
# this configuration rather than of one machine -- which is what makes them
# tracked. Without this module a fresh machine installs starship and then has
# no prompt until someone copies three lines out of local.sh.example.
#
# Loaded after keybinds.sh, matching the order local.sh had: integrations that
# install their own bindings come after ours. There is no actual collision --
# keybinds.sh takes Ctrl-F, fzf takes Ctrl-R, Ctrl-T and Alt-C.
#
# The `command -v` guards are the point of the module, not boilerplate: a
# machine without the flake still gets a working shell, just a plainer one.

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd. The binary ships its own shell
# integration, so no ~/.fzf.bash shim is involved.
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"

# starship: prompt. Overrides the PS1 that Ubuntu's stock ~/.bashrc sets.
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# direnv: per-directory environments, and `use flake` via nix-direnv. See
# docs/direnv.md.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
