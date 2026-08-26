# claude

Claude Code global configuration, managed as a the manifest deployer package. Tracks the
user-authored config files under `~/.claude/`; everything else there is
tool-managed state (sessions, history, plugin cache, credentials) and stays
untracked, with `.gitignore` guards in the repo root as a safety net.

## Tracked

| File | Purpose |
| --- | --- |
| `.claude/CLAUDE.md` | Global agent instructions (all projects) |
| `.claude/settings.json` | Permissions, enabled plugins, marketplaces, model, statusline, UI prefs |
| `.claude/statusline-command.sh` | Custom statusline script referenced by settings |
| `.claude/skills/project-status/` | Claude-specific skill: summarize a project's `.claude/` setup |
| `.claude/skills/suggest-optimization/` | Claude-specific skill: propose setup/workflow optimizations |

The two skills above are the only tracked ones. Everything else under
`~/.claude/skills/` is third-party and untracked — managed by skills.sh or a
vendor CLI, and reproducible from `~/.agents/.skill-lock.json`. Portable
skills live in the shared `~/.agents/skills/` tree; Claude Code does not read
that tree natively, so they appear here as relative symlinks into it.

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

- **Fresh machine:** no special ordering is needed. This is a `tree` row, so
  `~/.claude/` is always created as a real directory holding one symlink per
  tracked file — Claude Code's session state, history, and credentials stay
  outside the repo by construction rather than by `.gitignore` alone.
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

Migration executed 2026-07-23: superpowers removed (its systematic-debugging
and verification-before-completion skills salvaged into `agent-skills`, itself
since deleted — both proved redundant and superpowers remains installable);
OpenSpec 1.6.0 installed globally (custom profile: core workflows + verify,
onboard, bulk-archive) with per-repo adoption via `openspec init`; a
SessionStart hook in `settings.json` injects active-change state in
OpenSpec-enabled repos; CLAUDE.md gained the "Specs and Source of Truth"
section. Pilot repo: agy-plugin-cc.
