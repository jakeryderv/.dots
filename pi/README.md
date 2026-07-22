# pi

Global config for the Pi coding agent, managed as a GNU Stow package.

Mirrors `~/.pi/agent/`. Only **user-authored** config is tracked here; secrets
and tool-managed state stay in the live `~/.pi/` dir and are gitignored.

| Tracked | Tool-managed / secret (NOT tracked) |
|---------|-------------------------------------|
| `AGENTS.md` — global agent instructions | `auth.json` — credentials |
| `settings.json` — provider/model defaults, enabled models, installed `packages` | `npm/` — pi installs the `packages` here (328 MB; regenerated from `settings.json`) |
| `mcp.json` — MCP servers (`context7` hosted remote, pinned local `playwright`) | `sessions/`, `mcp-cache.json`, `mcp-npx-cache.json`, `run-history.jsonl`, `intercom/`, `trust.json` — runtime state |
| `extensions/` — custom TS extensions (`dump-system-prompt.ts`) | `~/.pi/web-search.json` (Exa API key), `exa-usage.json`, `playwright-profile/`, `rules/` — left in place |
| `themes/` — custom TUI theme (`carbonfox.json`; selected in `settings.json`) | |
| `skills/` — custom agent skills | |
| `prompts/` — prompt templates | |

> **Note:** `settings.json` is written by pi at runtime (`lastChangelogVersion`
> on updates, plus model/thinking/`enabledModels` changes from `/settings` and
> the model picker), so it will show up dirty in `git status`. Commit when a
> change is intentional; `git restore pi/.pi/agent/settings.json` to drop noise.

`settings.json`'s `packages` array is the source of truth for which npm packages
pi installs into `npm/node_modules`, so `npm/` is reproducible and not tracked.
No tracked file contains credentials — secrets live in `auth.json` and
`~/.pi/web-search.json`, both ignored.

## Dependencies

Copying this config is **not** enough on its own. Some features need system
binaries or secrets:

| Dependency | Needed for | How it's resolved |
|------------|-----------|-------------------|
| **Node.js + npm/npx** | pi itself; installing `packages`; running local MCP servers | system install |
| **GNU `stow`, `git`** | activating this config (symlinks) | system install |
| **Language servers** (pyright, typescript-language-server, rust-analyzer, gopls, …) | `pi-lens` LSP nav/diagnostics | install per-language as needed; pi-lens uses whatever is on `PATH`. ast-grep is bundled (no install) |
| **Chrome / Chromium** | `playwright` MCP browser automation | system install |
| **Provider credentials** | model access (Anthropic / OpenAI / Google) | `~/.pi/agent/auth.json` (run pi and log in; not tracked) |
| **Exa API key** | `pi-web-access` web search | `~/.pi/web-search.json` (not tracked) |
| **Network** | hosted Context7, first-run local MCP fetches, package installs, web search | — |

Self-contained (no extra setup): `pi-subagents`, `pi-intercom`, `pi-web-access`
fetch, and pi-lens's bundled ast-grep.

## Activate

`~/.pi/agent/` already exists once pi has run, so create it first to stop stow
from folding the whole `~/.pi` tree (which would pull runtime state and secrets
into the repo). Then stow links the config files back into place:

```bash
mkdir -p ~/.pi/agent
cd ~/.dots && stow pi
```

Fresh-machine order: install Node + git + stow → run pi once (installs
`packages`, prompts for provider login) → `stow pi` → then add the external deps
from the table above as you need them (language servers, Chrome, Exa key).

This symlinks `AGENTS.md`, `settings.json`, `mcp.json`, `extensions/`,
`themes/`, `skills/`, and `prompts/` into `~/.pi/agent/`, leaving `auth.json`,
`npm/`, `sessions/`, and the caches as real files alongside them.

The three top-level files (`AGENTS.md`, `settings.json`, `mcp.json`) are linked
as individual **file** symlinks, while `extensions/`, `themes/`, `skills/`, and
`prompts/` are linked as whole **directory** symlinks. That means new files
dropped into `extensions/`, `themes/`, `skills/`, or `prompts/` land inside this
repo automatically
(desired — they hold only
user-authored content), whereas any other file pi writes into `~/.pi/agent/`
stays a real local file and never enters the repo.

To remove the symlinks: `cd ~/.dots && stow -D pi`.

## Maintenance

**Package versions intentionally track latest.** The `packages` array in
`settings.json` lists bare specs (`npm:pi-lens`, no `@version`), so pi installs
the newest published version into `npm/node_modules` on each resolve. This is a
deliberate convenience choice for packages I actively use and trust enough to
track latest. For tighter supply-chain or reproducibility needs — especially for
third-party/community packages — add `@x.y.z` to a spec (e.g.
`npm:pi-lens@1.2.3`).

Local MCP server versions in `mcp.json` are pinned (`@playwright/mcp`) for
reproducibility, so they won't auto-update — bump them deliberately now and then
(e.g. `npx @playwright/mcp@latest --version` to check current). Context7 uses
its hosted MCP endpoint, so there is no local Context7 package version to bump.

The playwright server uses its own default browser-profile location (no
`--user-data-dir`), keeping the config portable across machines.
