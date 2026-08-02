#!/usr/bin/env bash
# install-tmux-sessionizer.sh - Install ThePrimeagen's tmux-sessionizer.
# Assumes: curl + sha256sum + network. Fetches a reviewed, pinned commit.

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
COMMIT="7edf8211e36368c29ffc0d2c6d5d2d350b4d729b"
EXPECTED_SHA256="9242b732dd46faddeaf41ebed5e27058e9d140761908ab16b61cd6ff3b9b6b1e"
TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/tmux-sessionizer.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

for command in curl sha256sum; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Error: required command '$command' was not found" >&2
        exit 1
    }
done

mkdir -p "$INSTALL_DIR"

echo "Downloading tmux-sessionizer at $COMMIT..."
curl -fL --retry 3 -o "$TMP_FILE" \
    "https://raw.githubusercontent.com/ThePrimeagen/tmux-sessionizer/$COMMIT/tmux-sessionizer"

ACTUAL_SHA256=$(sha256sum "$TMP_FILE" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Error: SHA-256 verification failed for tmux-sessionizer" >&2
    exit 1
fi

install -m 0755 "$TMP_FILE" "$INSTALL_DIR/tmux-sessionizer"

echo "✓ tmux-sessionizer installed to $INSTALL_DIR/tmux-sessionizer"

echo ""
echo "Add to your tmux.conf:"

echo "  bind-key -r f run-shell 'tmux neww ~/.local/bin/tmux-sessionizer'"
