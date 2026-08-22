# pi

Global config for the Pi coding agent, managed as a manifest deployer package.

Mirrors `~/.pi/agent/`. Only **user-authored** config is tracked here; secrets
and tool-managed state stay in the live `~/.pi/` dir and are gitignored.

| Tracked | Tool-managed / secret (NOT tracked) |
|---------|-------------------------------------|
| `AGENTS.md` — global agent instructions | `auth.json` — credentials |
| `settings.json` — provider/model defaults, scoped model cycling, installed `packages` | `npm/`, `git/` — Pi's package installations, regenerated from `settings.json` |
| `mcp.json` — MCP servers (`context7` hosted remote) | `sessions/`, `mcp-cache.json`, `models-store.json`, `run-history.jsonl`, `intercom/`, `trust.json` — runtime state |
| `extensions/` — custom TS extensions (`dump-system-prompt.ts`) | `fff/`, `pi-hermes-memory/`, `projects-memory/`, `missions/`, `tmp/` — extension state |
| `themes/` — custom TUI theme (`carbonfox.json`; selected in `settings.json`) | `~/.pi/artifacts/`, `workflows/`, `web-search-cache/`, `rules/` — generated state |
| `skills/` — reserved for tracked Pi-only skills; shared skills come from `~/.agents/skills/` | `~/.pi/web-search.json` (provider keys), `exa-usage.json`, `playwright-profile/` — machine-local state |
| `prompts/` — tracked prompt templates | |

> **Note:** `settings.json` is written by pi at runtime (`lastChangelogVersion`
> on updates, plus model/thinking/`enabledModels` changes from `/settings` and
> the model picker), so it will show up dirty in `git status`. Commit when a
> change is intentional; `git restore home/pi/agent/settings.json` to drop noise.

`settings.json`'s `packages` array is the source of truth for which npm packages
Pi installs into `npm/node_modules`, so `npm/` can be rebuilt and is not tracked.
Bare package specs intentionally resolve current releases rather than reproducing
an exact historical dependency tree.
No tracked file contains credentials — secrets live in `auth.json` and
`~/.pi/web-search.json`, both ignored.

## Dependencies

Copying this config is **not** enough on its own. Some features need system
binaries or secrets:

| Dependency | Needed for | How it's resolved |
|------------|-----------|-------------------|
| **Node.js + npm/npx** | Pi itself; installing `packages`; running local MCP servers | system install |
| **Pi CLI** | Coding-agent runtime | `bash tools/install-pi.sh` (tracks the latest release) |
| **`just`, `git`** | activating this config (symlinks) | system install |
| **Language servers** (pyright, typescript-language-server, rust-analyzer, gopls, …) | `pi-lens` LSP nav/diagnostics | install per-language as needed; pi-lens uses whatever is on `PATH`. ast-grep is bundled (no install) |
| **Playwright CLI + Chromium** | Shared browser automation skill | Install with [`tools/install-playwright-cli.sh`](../tools/install-playwright-cli.sh); see [`agent-skills`](agent-skills.md) |
| **Provider credentials** | model access (Anthropic / OpenAI / Google) | `~/.pi/agent/auth.json` (run pi and log in; not tracked) |
| **Exa API key** | `pi-web-access` web search | `~/.pi/web-search.json` (not tracked) |
| **Network** | hosted Context7, first-run local MCP fetches, package installs, web search | — |

Self-contained (no extra setup): `pi-subagents`, `pi-intercom`, `pi-web-access`
fetch, and pi-lens's bundled ast-grep.

## Activate

```bash
just apply pi
```

This is a `tree` row, so `~/.pi/` is always a real directory holding one symlink
per tracked file. pi's runtime state and secrets (`auth.json`, `sessions/`,
`npm/`) stay outside the repo by construction — no need to pre-create
directories to prevent a whole-tree symlink.

Fresh-machine order: install Node + git + just → `bash tools/install-pi.sh` →
`just apply pi` → run Pi (it installs the tracked `packages` and prompts for
provider login) → add optional external dependencies as needed (language
servers, Chromium, Exa key).

The manifest's `tree` mode keeps `~/.pi/` and every nested target directory real.
Each tracked file—whether `AGENTS.md` or
`extensions/dump-system-prompt.ts`—is linked individually into that tree.
Runtime state and secrets remain ordinary local files beside those links.

Consequently, a new extension, theme, Pi-only skill, or prompt created directly
under live `~/.pi/agent/` stays machine-local. Add user-authored resources under
`home/pi/agent/` in this repo, commit them, and run `just apply pi`; do not expect
live resource directories to write through into the repository.

To remove the symlinks: `cd ~/.dots && just unlink pi`.

## Maintenance

**Package versions intentionally track latest.** The `packages` array in
`settings.json` lists bare specs (`npm:pi-lens`, no `@version`), so pi installs
the newest published version into `npm/node_modules` on each resolve. This is a
deliberate convenience choice for packages I actively use and trust enough to
track latest. For tighter supply-chain or reproducibility needs — especially for
third-party/community packages — add `@x.y.z` to a spec (e.g.
`npm:pi-lens@1.2.3`).

Context7 uses its hosted MCP endpoint, so there is no local Context7 package
version to bump. Portable skills, including browser automation, Cloudflare
tooling, and Railway, come from the shared `~/.agents/skills/` tree rather than
being copied into Pi; see [`agent-skills`](agent-skills.md).

Inspect current live disk use instead of documenting a value that changes with
package releases:

```bash
du -sh ~/.pi ~/.pi/agent/npm
```
