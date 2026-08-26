#!/usr/bin/env bash
# Install or update the two Cloudflare CLIs in the active Node installation:
#
#   cf        the newer, generated CLI covering the whole Cloudflare API
#             (DNS, zones, registrar, images, accounts, Workers, ...)
#   wrangler  the Workers build toolchain -- bundling, Miniflare dev server,
#             wrangler.jsonc, secrets, tail
#
# They are separate products with overlapping surface, and Cloudflare is
# converging them: the wrangler package already ships a `cf-wrangler` binary,
# and `cf --local` routes to a wrangler dev / cf dev Miniflare session. Until
# that lands, both are worth having. Installed together because they share a
# vendor, an install mechanism, and an upgrade cadence.
#
# Neither package nor any of its Cloudflare dependencies declares an install
# lifecycle script, so --ignore-scripts costs nothing here.
#
# Authentication is NOT handled here, and the two CLIs do not share it. Each
# keeps its own OAuth grant in its own store:
#
#   cf auth login        -> ~/.config/cloudflare/config/default.json
#   wrangler login       -> ~/.config/.wrangler/config/default.toml
#
# The Cloudflare Claude Code plugin's five MCP servers are a third, independent
# grant. See docs/claude.md.
#
# Assumes: Linux x86_64, Node.js, npm, network access, and a writable global
# npm prefix (the active nvm installation satisfies this without sudo).

set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "install-cloudflare: npm is required" >&2
    exit 1
fi

npm install -g --ignore-scripts cf@latest wrangler@latest

for binary in cf wrangler; do
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "install-cloudflare: npm completed but $binary is not on PATH" >&2
        exit 1
    fi
done

printf 'Installed cf %s\n' "$(cf --version | grep -o 'v[0-9][^ ]*' | tr -d v)"
printf 'Installed wrangler %s\n' "$(wrangler --version)"

cat <<'NOTE'

Each CLI authenticates separately:
  cf auth login       (then: cf context set account-id <id>)
  wrangler login
NOTE
