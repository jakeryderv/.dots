# pi

Global config for the Pi coding agent, managed as a GNU Stow package.

Mirrors `~/.pi/agent/`. Only **user-authored** config is tracked here; secrets
and tool-managed state stay in the live `~/.pi/` dir and are gitignored.

| Tracked | Tool-managed / secret (NOT tracked) |
|---------|-------------------------------------|
| `AGENTS.md` — global agent instructions | `auth.json` — credentials |
| `settings.json` — provider/model defaults, enabled models, installed `packages` | `npm/` — pi installs the `packages` here (328 MB; regenerated from `settings.json`) |
| `mcp.json` — MCP servers (`context7`, `playwright`; versions pinned) | `sessions/`, `mcp-cache.json`, `mcp-npx-cache.json`, `run-history.jsonl`, `intercom/`, `trust.json` — runtime state |
| `extensions/` — custom TS extensions (`dump-system-prompt.ts`) | `~/.pi/web-search.json` (Exa API key), `exa-usage.json`, `playwright-profile/`, `rules/` — left in place |
| `themes/` — custom TUI theme (`carbonfox.json`; selected in `settings.json`) | |

> **Note:** `settings.json` is written by pi at runtime (`lastChangelogVersion`
> on updates, plus model/thinking/`enabledModels` changes from `/settings` and
> the model picker), so it will show up dirty in `git status`. Commit when a
> change is intentional; `git restore pi/.pi/agent/settings.json` to drop noise.

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

The three top-level files (`AGENTS.md`, `settings.json`, `mcp.json`) are linked
as individual **file** symlinks, while `extensions/` and `themes/` are linked as
whole **directory** symlinks. That means new files dropped into `extensions/` or
`themes/` land inside this repo automatically (desired — they hold only
user-authored content), whereas any other file pi writes into `~/.pi/agent/`
stays a real local file and never enters the repo.

To remove the symlinks: `cd ~/.dots && stow -D pi`.

## Maintenance

MCP server versions in `mcp.json` are pinned (`context7`, `@playwright/mcp`) for
reproducibility, so they won't auto-update — bump them deliberately now and then
(e.g. `npx @playwright/mcp@latest --version` to check current).

The playwright server uses its own default browser-profile location (no
`--user-data-dir`), keeping the config portable across machines.
