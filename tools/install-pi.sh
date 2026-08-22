#!/usr/bin/env bash
# Install or update the latest Pi coding agent release in the active Node
# installation. Pi's tracked settings restore its extension packages separately.
#
# Assumes: Linux x86_64, Node.js, npm, network access, and a writable global
# npm prefix (the active nvm installation satisfies this without sudo).

set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "install-pi: npm is required" >&2
    exit 1
fi

npm install -g --ignore-scripts @earendil-works/pi-coding-agent@latest

if ! command -v pi >/dev/null 2>&1; then
    echo "install-pi: npm completed but pi is not on PATH" >&2
    exit 1
fi

printf 'Installed Pi %s\n' "$(pi --version)"
