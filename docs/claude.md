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

The two skills above are the only Claude-specific tracked ones. Skills shared
across agents are tracked in the `agent-skills` package (see
[agent-skills.md](agent-skills.md)) and linked into `.claude/skills/` from
there. Everything else under
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

## Cloudflare toolchain

The `cloudflare@cloudflare` plugin in `settings.json` is only one of three
independent layers that reach the same Cloudflare account, each with its own
credential store:

| Layer | Installed by | Credential |
| --- | --- | --- |
| 11 skills + 2 commands | `settings.json` (plugin cache) | none — documentation only |
| 5 remote MCP servers | the plugin's `.mcp.json` | Claude Code's own OAuth store |
| `cf` and `wrangler` CLIs | [`install-npm-globals.sh`](../tools/install-npm-globals.sh) | `~/.config/cloudflare/`, `~/.config/.wrangler/` |

Three OAuth grants means three things to re-authenticate on a new machine and
three to revoke. The MCP servers and the `cf` CLI overlap heavily — `cf tools`
emits the same tool definitions locally that the remote servers expose — so
the MCP set is a convenience, not a dependency.

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
onboard, bulk-archive) with per-repo adoption via `openspec init`, itself since
removed — the spec workflow went unused, and its SessionStart hook and the
CLAUDE.md "Specs and Source of Truth" section went with it. Pilot repo:
agy-plugin-cc.
