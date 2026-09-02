#!/usr/bin/env bash
# Install or update the CLIs that come from npm because nixpkgs does not carry
# them. Everything nixpkgs does carry lives in flake.nix instead.
#
# This is a script rather than four documented `npm install` lines because two
# of them encode a decision: --ignore-scripts closes the install-lifecycle
# supply-chain hole (none of these packages declare one, so it costs nothing),
# and playwright-cli needs a second command to fetch its browser.
#
# What each CLI is, and how each authenticates, is in tools/README.md and
# docs/claude.md -- not repeated here.
#
# Assumes: Linux x86_64, Node.js, npm, network access, and a writable global
# npm prefix. Node comes from flake.nix, whose store path is read-only, so
# ~/.npmrc sets prefix=~/.npm-global -- see shell/exports.sh for the PATH entry.
#
# Re-runnable: everything is pinned to @latest, so this updates as well as
# installs.

set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "install-npm-globals: npm is required" >&2
    exit 1
fi

npm install -g --ignore-scripts \
    @earendil-works/pi-coding-agent@latest \
    cf@latest \
    wrangler@latest

# Deliberately not --ignore-scripts: installed normally, then told to fetch its
# browser, which lands in ~/.cache/ms-playwright rather than the npm prefix.
npm install -g @playwright/cli@latest
playwright-cli install-browser chromium

for binary in pi cf wrangler playwright-cli; do
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "install-npm-globals: npm completed but $binary is not on PATH" >&2
        exit 1
    fi
done

printf 'pi             %s\n' "$(pi --version)"
printf 'cf             %s\n' "$(cf --version | grep -o 'v[0-9][^ ]*' | tr -d v)"
printf 'wrangler       %s\n' "$(wrangler --version)"
printf 'playwright-cli %s\n' "$(playwright-cli --version)"

cat <<'NOTE'

Each CLI authenticates separately:
  cf auth login       (then: cf context set account-id <id>)
  wrangler login
NOTE
