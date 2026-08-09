#!/usr/bin/env bash
# install-glow.sh - Install glow (Charm's markdown renderer) via Charm's apt repo.
# Used by shell/llm.sh to pretty-print LLM output. Re-run anytime to update.
# Assumes: Debian/Ubuntu (apt/sudo), curl + gpg, network. Installs latest.

set -euo pipefail # Exit on error, unset vars, and pipe failures

KEYRING="/etc/apt/keyrings/charm.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/charm.list"

if command -v glow &>/dev/null; then
    echo "glow already installed: $(glow --version)"
    echo "Continuing to ensure the repo is configured and glow is up to date..."
fi

echo "Adding Charm apt repository (requires sudo)..."
sudo mkdir -p /etc/apt/keyrings

if [ ! -s "$KEYRING" ]; then
    echo "Importing Charm signing key..."
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o "$KEYRING"
else
    echo "Charm signing key already present."
fi

if [ ! -f "$SOURCE_LIST" ]; then
    echo "Adding Charm source list..."
    echo "deb [signed-by=$KEYRING] https://repo.charm.sh/apt/ * *" |
        sudo tee "$SOURCE_LIST" >/dev/null
else
    echo "Charm source list already present."
fi

echo "Updating package lists..."
sudo apt update

echo "Installing glow..."
sudo apt install -y glow

echo ""
echo "✓ Successfully installed glow!"
glow --version

echo ""
echo "Used by bash/llm.sh (MANAI_RENDERER=glow) to render markdown output."
echo "Test it:  echo '# hello' | glow"
