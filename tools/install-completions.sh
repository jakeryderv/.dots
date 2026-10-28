#!/usr/bin/env bash
# Regenerate the Bash and Zsh completions of every tool that can print its own,
# into the user completion directories both rc files already search:
#
#   ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/COMMAND
#   ${XDG_DATA_HOME:-~/.local/share}/zsh/site-functions/_COMMAND
#
# This is a script rather than the documented one-liners because a generated
# completion goes stale silently: the tool updates, its file does not, and Tab
# offers the old flags. Run it after updating any tool listed below (or just
# periodically); `dots install completions`.
#
# Not here, on purpose: completions that ship as files rather than from a
# generator -- the fd, Just and Tealdeer archives, apt packages -- and are
# refreshed with the binary they came with. docs/software.md records which is
# which.
#
# Re-runnable. A tool that is not installed is skipped; a generator that fails
# or prints nothing leaves the existing file alone.

set -euo pipefail

data="${XDG_DATA_HOME:-$HOME/.local/share}"
bash_dir="$data/bash-completion/completions"
zsh_dir="$data/zsh/site-functions"

# Command names, in the order they are reported.
tools=(ast-grep bun cargo delta herdr lazygit maturin rustup starship tree-sitter tuios uv)

# Print NAME's completion script for SHELL (bash or zsh) on stdout.
generate() {
    local name=$1 shell=$2
    case $name in
    ast-grep) ast-grep completions "$shell" ;;
    # `bun completions` installs into a directory it picks from $SHELL;
    # with stdout not a terminal it prints the script instead.
    bun) SHELL="/bin/$shell" bun completions ;;
    # Cargo's completions come from rustup, for the active toolchain.
    cargo) rustup completions "$shell" cargo ;;
    delta) delta --generate-completion "$shell" ;;
    herdr) herdr completion "$shell" ;;
    lazygit) lazygit completion "$shell" ;;
    maturin) maturin completions "$shell" ;;
    rustup) rustup completions "$shell" rustup ;;
    starship) starship completions "$shell" ;;
    tree-sitter) tree-sitter complete --shell "$shell" ;;
    tuios) tuios completion "$shell" ;;
    uv) uv generate-shell-completion "$shell" ;;
    *) return 1 ;;
    esac
}

mkdir -p "$bash_dir" "$zsh_dir"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

status=0
for name in "${tools[@]}"; do
    if ! command -v "$name" >/dev/null 2>&1; then
        echo "skip     $name (not installed)"
        continue
    fi
    for shell in bash zsh; do
        if [[ $shell == bash ]]; then
            dest="$bash_dir/$name"
        else
            dest="$zsh_dir/_$name"
        fi
        if ! generate "$name" "$shell" >"$tmp" 2>/dev/null || [[ ! -s $tmp ]]; then
            echo "FAILED   $name ($shell); kept $dest" >&2
            status=1
        elif cmp -s "$tmp" "$dest"; then
            echo "current  $name ($shell)"
        else
            cp "$tmp" "$dest"
            echo "updated  $name ($shell)"
        fi
    done
done

# Both shells read a completion file when it is first used, so a new shell sees
# the update. (Zsh's compinit dump records only which command maps to which
# function, and rebuilds itself when a file is added.)
echo "Open a new shell to pick up updates."
exit "$status"
