#!/usr/bin/env bash
# install-fzf-full.sh - Install FZF with shell integrations

set -e

echo "Installing FZF with shell integrations..."

# Clone FZF repo
if [ -d ~/.fzf ]; then
	echo "FZF already cloned, updating..."
	cd ~/.fzf && git pull
else
	echo "Cloning FZF repository..."
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
fi

# Run installer (installs binary + shell integrations)
echo "Running FZF installer..."
~/.fzf/install --all

echo ""
echo "✓ FZF installed successfully!"
echo "Restart your shell or run: source ~/.bashrc"
