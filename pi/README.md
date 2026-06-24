# pi

Global config for the Pi coding agent, managed as a GNU Stow package.

Mirrors `~/.pi/agent/`. Only **user-authored** config is tracked here; secrets
and tool-managed state stay in the live `~/.pi/` dir and are gitignored.

| Tracked | Tool-managed / secret (NOT tracked) |
|---------|-------------------------------------|
| `AGENTS.md` — global agent instructions | `auth.json` — credentials |
| `settings.json` — provider/model defaults, enabled models, installed `packages` | `npm/` — pi installs the `packages` here (328 MB; regenerated from `settings.json`) |
| `mcp.json` — MCP servers (`context7`, `playwright`) | `sessions/`, `mcp-cache.json`, `mcp-npx-cache.json`, `run-history.jsonl`, `intercom/` — runtime state |
| `extensions/` — custom TS extensions (`dump-system-prompt.ts`) | `~/.pi/web-search.json` (Exa API key), `exa-usage.json`, `playwright-profile/`, `rules/` — left in place |
| `themes/` — custom TUI theme (`carbonfox.json`; selected in `settings.json`) | |

`settings.json`'s `packages` array is the source of truth for which npm packages
pi installs into `npm/node_modules`, so `npm/` is reproducible and not tracked.
No tracked file contains credentials — secrets live in `auth.json` and
`~/.pi/web-search.json`, both ignored.

## Activate

`~/.pi/agent/` already exists once pi has run, so create it first to stop stow
from folding the whole `~/.pi` tree (which would pull runtime state and secrets
into the repo). Then stow links the config files back into place:

```bash
mkdir -p ~/.pi/agent
cd ~/.dots && stow pi
```

This symlinks `AGENTS.md`, `settings.json`, `mcp.json`, `extensions/`, and
`themes/` into `~/.pi/agent/`, leaving `auth.json`, `npm/`, `sessions/`, and the
caches as real files alongside them.

To remove the symlinks: `cd ~/.dots && stow -D pi`.
