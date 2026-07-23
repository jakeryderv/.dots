# claude

Claude Code global configuration, managed as a GNU Stow package. Tracks the
user-authored config files under `~/.claude/`; everything else there is
tool-managed state (sessions, history, plugin cache, credentials) and stays
untracked, with `.gitignore` guards in the repo root as a safety net.

## Tracked

| File | Purpose |
| --- | --- |
| `.claude/CLAUDE.md` | Global agent instructions (all projects) |
| `.claude/settings.json` | Permissions, enabled plugins, marketplaces, model, statusline, UI prefs |
| `.claude/statusline-command.sh` | Custom statusline script referenced by settings |

Skills under `~/.claude/skills/` are owned by the separate `agent-skills`
package (shared across agents via `~/.agents/skills/`).

## Deliberately not tracked

- `~/.claude.json` — a large mutable state file (telemetry, per-project state)
  that also holds user-scope MCP server registrations. Re-register MCP servers
  on a new machine with:

  ```bash
  claude mcp add railway -s user -- railway mcp
  claude mcp add context7 -s user -t http https://mcp.context7.com/mcp \
    --header "CONTEXT7_API_KEY: \${CONTEXT7_API_KEY}"
  ```

  (`CONTEXT7_API_KEY` comes from the untracked machine-local bash config;
  the railway MCP needs the `railway` CLI installed and authed.)
- `~/.claude/settings.local.json` — machine-local permission grants.
- Plugin installs — declared in `settings.json` (`enabledPlugins` +
  `extraKnownMarketplaces`); Claude Code materializes the plugin cache itself.

## Caveats

- **Fresh machine:** run Claude Code once before stowing so `~/.claude/` exists
  as a real directory, or stow with `--no-folding`. If stow folds the whole
  directory into a symlink, Claude Code will write session state, history, and
  credentials into this repo (the `.gitignore` guards are the backstop).
- **Symlinked settings.json:** Claude Code rewrites `settings.json` when
  plugins are enabled/disabled or settings change via the UI. If it ever
  replaces the file atomically (rename-over), the symlink breaks silently and
  the repo copy goes stale — `dots status claude` will show it. Re-adopt with
  `dots adopt --apply claude` if that happens.

## History note

Tracking started 2026-07-22, immediately before migrating the planning/spec
workflow from the superpowers plugin to OpenSpec — so the initial commit
records the superpowers-era configuration, and the migration is documented by
the commits that follow.
