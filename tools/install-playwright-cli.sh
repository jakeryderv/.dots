#!/usr/bin/env bash
# Install/update the shared Playwright CLI runtime and its Chromium browser.
# Mutates the active Node installation's global npm packages and
# ~/.cache/ms-playwright. The Agent Skill itself is untracked (skills.sh).

set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "install-playwright-cli: npm is required" >&2
    exit 1
fi

npm install -g @playwright/cli@latest
playwright-cli install-browser chromium

echo "Installed playwright-cli $(playwright-cli --version)"
