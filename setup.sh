#!/usr/bin/env bash
# setup.sh - Install the repo-local dots CLI entrypoint.
#
# This does not stow any dotfile packages. It only links ~/.local/bin/dots to
# this repo's _dots/bin/dots so the orchestration CLI can manage Stow.
#
# Assumes: bash + coreutils. Run from anywhere inside the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$SCRIPT_DIR")"
DOTS_BIN="$REPO_ROOT/_dots/bin/dots"
TARGET_DIR="${DOTS_BIN_DIR:-$HOME/.local/bin}"
TARGET="$TARGET_DIR/dots"

if [[ ! -x "$DOTS_BIN" ]]; then
    echo "error: dots CLI is not executable: $DOTS_BIN" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    current="$(readlink -f "$TARGET" 2>/dev/null || true)"
    desired="$(readlink -f "$DOTS_BIN")"
    if [[ "$current" == "$desired" ]]; then
        echo "dots already linked: $TARGET -> $DOTS_BIN"
        exit 0
    fi

    backup="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    mv "$TARGET" "$backup"
    echo "backed up existing dots entrypoint: $backup"
fi

ln -s "$DOTS_BIN" "$TARGET"
echo "linked dots: $TARGET -> $DOTS_BIN"

case ":$PATH:" in
*":$TARGET_DIR:"*) ;;
*) echo "warning: $TARGET_DIR is not on PATH" >&2 ;;
esac
