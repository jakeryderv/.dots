#!/usr/bin/env bash
# install-tmux-sessionizer.sh - Install ThePrimeagen's tmux-sessionizer.
# Assumes: curl + network. Fetches latest from master (not pinned).

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "Downloading tmux-sessionizer..."
curl -fL -o "$INSTALL_DIR/tmux-sessionizer" \
	https://raw.githubusercontent.com/ThePrimeagen/tmux-sessionizer/master/tmux-sessionizer

chmod +x "$INSTALL_DIR/tmux-sessionizer"

echo "✓ tmux-sessionizer installed to $INSTALL_DIR/tmux-sessionizer"

echo ""
echo "Add to your tmux.conf:"

echo "  bind-key -r f run-shell 'tmux neww ~/.local/bin/tmux-sessionizer'"
