#!/usr/bin/env bash
# Install or update the CLIs that come from npm because nixpkgs does not carry
# them, or carries them only with a Nix-built browser. Everything else nixpkgs
# carries lives in flake.nix instead.
#
# This is a script rather than five documented `npm install` lines because
# three of them encode a decision: --ignore-scripts closes the install-lifecycle
# supply-chain hole (none of those packages declare one, so it costs nothing),
# playwright-cli needs a second command to fetch its browser, and mermaid-cli
# needs its install scripts to run at all.
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

# Also not --ignore-scripts: puppeteer's postinstall is what downloads the
# Chrome that `mmdc` renders with, into ~/.cache/puppeteer. Skipping it
# installs a binary that fails on first use.
#
# nixpkgs does have mermaid-cli (11.16.0 at the current lock), so this is the
# one entry here that fails the "absent from nixpkgs" test. It stays on npm
# because the nixpkgs build wraps nixpkgs' own chromium, which is the
# browser-under-Nix category tools/README.md records as broken on this host.
# Headless was not tested; revisit if that finding changes.
npm install -g @mermaid-js/mermaid-cli@latest

for binary in pi cf wrangler playwright-cli mmdc; do
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "install-npm-globals: npm completed but $binary is not on PATH" >&2
        exit 1
    fi
done

printf 'pi             %s\n' "$(pi --version)"
printf 'cf             %s\n' "$(cf --version | grep -o 'v[0-9][^ ]*' | tr -d v)"
printf 'wrangler       %s\n' "$(wrangler --version)"
printf 'playwright-cli %s\n' "$(playwright-cli --version)"
printf 'mmdc           %s\n' "$(mmdc --version)"

cat <<'NOTE'

Each CLI authenticates separately:
  cf auth login       (then: cf context set account-id <id>)
  wrangler login
NOTE
