# serena

Documentation-only entry for [Serena](https://github.com/oraios/serena) (MIT,
`oraios/serena`) — **nothing is deployed**. Serena is an MCP server that gives a
coding agent LSP-backed semantic code tools: symbol lookup, reference search,
rename, replace-symbol-body, diagnostics.

`~/.serena/serena_config.yml` is deliberately not tracked. Serena mixes user
config with machine state in that one file — the `projects:` list holds
absolute local paths and is rewritten by the agent whenever a project is added
or removed (`serena_config.py`: *"which is updated when projects are added or
removed"*) — and this repo is public. Same policy as the codex package, and for
the same reason: there is no way to split the file. Serena's `.local.yml`
override mechanism is **project-scoped only**; no global equivalent exists.
The dashboard's `save_serena_config` endpoint can also rewrite the file at any
time, so it would show up dirty unpredictably.

## Install (as of 2026-07-26, Serena 1.6.1)

```bash
uv tool install -p 3.13 serena-agent
serena init
```

- Binaries land in `~/.local/bin`: `serena`, `serena-agent`, `serena-hooks`.
- The venv is `~/.local/share/uv/tools/serena-agent/` — ~100 MB, Python
  3.13.11, 157 packages. System Python is untouched (`requires-python` is
  `>=3.11,<3.15`; the `-p 3.13` is just a pin, uv fetches it).
- `serena init` only writes `~/.serena/serena_config.yml` (mode 0600) and sets
  the LSP backend. It registers nothing.
- Language servers download lazily on first use, per language — Python via
  `uvx` (pinned Pyright, separate from the `pyright` uv tool already
  installed), TypeScript via npm (needs nvm's node on PATH when the MCP server
  is spawned).

## Recreating the user-authored config

Exactly one setting differs from what `serena init` generates:

```yaml
web_dashboard_open_on_launch: false   # keep web_dashboard: true
```

The dashboard is a Flask app on `127.0.0.1:24282` serving live logs, per-tool
call statistics, and config/memory editing. Worth keeping enabled — the tool
stats are the only way to see whether the agent actually *uses* Serena's tools
— but with per-project registration it would otherwise open a browser tab on
every session start. Reach it manually at
<http://localhost:24282/dashboard/> (24283+ if several projects are running).

## Wiring up a project

Per-project, run inside the repo:

```bash
claude mcp add serena -- serena start-mcp-server --context claude-code --project "$(pwd)"
```

**Do not run `serena setup claude-code`.** Its handler shells out to
`claude mcp add --scope user serena -- ... --project-from-cwd`, i.e. a global
registration — the opposite of per-project.

The `claude-code` context already excludes `read_file`, `list_dir`,
`find_file`, `search_for_pattern`, `create_text_file`, and
`execute_shell_command`, since Claude Code covers those itself.

## Deliberately not tracked

- `~/.serena/serena_config.yml` — see above; update the snippet here when the
  user-authored parts change.
- `~/.serena/memories/` — agent-written project memories.
- Per-project `.serena/` dirs — `project.yml` belongs in each project's own
  repo, and Serena gitignores its `project.local.yml` sibling. Nothing
  project-related belongs in this repo.

## Status / caveats

Installed 2026-07-26 as an **experiment, not yet evaluated**. Open questions
worth resolving before deciding it earns its place:

- Serena's Claude Code integration has been frozen since **April 2026**: the
  `claude-code.yml` context was last touched 2026-04-25, the "models resist
  Serena's tools" warning names **Opus 4.7**, and the published evaluation
  results are all **Opus 4.6**. Nothing in the repo mentions Opus 4.8 or 5, so
  there is no upstream evidence either way for the current model.
- Upstream's workarounds are aggressive: a full system-prompt override
  (`claude --system-prompt="$(serena prompts print-cc-system-prompt-override)"`)
  and `serena-hooks` reminder hooks (**alpha**). Neither is enabled here.
  Deliberately running plain first to see whether the tools get used unprompted.
- The `auto-approve` hook is intentionally **not** enabled: it blanket-approves
  Serena's destructive tools (`rename_symbol`, `replace_symbol_body`) whenever
  Claude Code is in `acceptEdits` or `auto` mode.
- Memories are on by default (`base_modes: [interactive, editing]`) and overlap
  with the OpenSpec workflow. Add the `no-memories` mode at registration time
  if that becomes a second competing source of truth.

## Notes

- No telemetry (no PostHog/Sentry/Segment/etc.). One outbound call: the
  dashboard GETs `https://oraios-software.de/serena_news.json` on start for
  release announcements — ETag-cached, 10 s timeout, failures ignored, no
  payload about the machine. Everything else is localhost or GitHub.
- Language-server downloads are hardened: pinned versions, SHA256 verification,
  host allowlists, zip-slip-safe extraction, installed outside the project.
- The JetBrains backend (move/inline/type-hierarchy/debugger) is a paid plugin
  and irrelevant here — the free LSP backend is what's configured.

## Uninstall

```bash
uv tool uninstall serena-agent
rm -rf ~/.serena
# plus: claude mcp remove serena, in each registered project
```
