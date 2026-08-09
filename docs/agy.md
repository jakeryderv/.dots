# agy

Documentation-only entry for the Google Antigravity CLI (`agy`) — **nothing is
stowed**. Same policy and reasoning as the `codex` package: agy's config files
mix user settings with machine state (`trustedWorkspaces` lists local project
paths, `config/config.json` carries the machine hostname), the CLI rewrites
them freely, and this repo is public.

agy lives in `~/.gemini/` (shared Gemini-CLI home) with agy-specific state
under `~/.gemini/antigravity-cli/`.

## Recreating the user-authored config

The only non-default settings worth carrying to a new machine, as of
2026-07-23 — agy creates everything else (including trust entries) on use:

- `~/.gemini/antigravity-cli/settings.json`: `"enableTelemetry": false`
- `~/.gemini/settings.json`: session retention 30d, `auth.selectedType`
  `oauth-personal` (set automatically on first `agy` login)

Keybindings (`antigravity-cli/keybindings.json`) are defaults; nothing to
carry.

## Deliberately not tracked

- `~/.gemini/**` — OAuth credentials (`oauth_creds.json`), conversation
  databases, history, `brain/`, trust data, caches. Update the snippet above
  if user-authored settings change.

## Related

- The **agy plugin for Claude Code** (`agy@jakeryderv`) is tracked via the
  `claude` package (`enabledPlugins` + `extraKnownMarketplaces` in
  `settings.json`). Since 2026-07-25 it is served by the
  [jakeryderv/agent-plugins](https://github.com/jakeryderv/agent-plugins)
  marketplace, which is only an index — the plugin itself still lives in
  [jakeryderv/agy-plugin-cc](https://github.com/jakeryderv/agy-plugin-cc) and
  is pulled `git-subdir` from `plugins/agy` at a pinned tag. Its job/session
  state lives in `~/.agy-plugin/` (untracked state).
- Skills: agy reads `~/.agents/skills/` directly — managed per the
  `agent-skills` package (skills.sh + vendor CLIs).
- History note (2026-07-23): deleted `~/.gemini/GEMINI.md` — the twin of
  codex's stale "lean-ctx" instructions (mandated `ctx_*` tools from a
  since-removed MCP server) — and `~/.gemini/skills/`, 11 stale pre-
  consolidation copies of skills now served fresh from `~/.agents/skills/`.
