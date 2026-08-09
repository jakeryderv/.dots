# codex

Documentation-only entry for the OpenAI Codex CLI — **nothing is deployed**.
`~/.codex/config.toml` is deliberately not tracked: codex mixes user config
with machine state in that one file (`[projects.*] trust_level` entries that
list local project paths and churn on every newly trusted directory), and this
repo is public. Same policy as the pi package's untracked `trust.json`, except
codex gives no way to split the file.

## Recreating the user-authored config

The settings worth carrying to a new machine, as of 2026-07-22 — merge into
`~/.codex/config.toml` (codex creates the rest, including trust entries, on
use):

```toml
approvals_reviewer = "auto_review"
model = "gpt-5.6-sol"
model_reasoning_effort = "high"

[mcp_servers.railway]
args = ["mcp"]
command = "railway"

[mcp_servers.context7]
url = "https://mcp.context7.com/mcp"
env_http_headers = { "CONTEXT7_API_KEY" = "CONTEXT7_API_KEY" }

[tui]
status_line = [
    "model-with-reasoning",
    "current-dir",
    "git-branch",
    "permissions",
    "approval-mode",
    "context-used",
]
status_line_use_colors = true
theme = "base16"
```

(`CONTEXT7_API_KEY` comes from the untracked machine-local bash config; the
railway MCP needs the `railway` CLI installed and authed.)

## Deliberately not tracked

- `~/.codex/config.toml` — see above; update the snippet here when the
  user-authored parts change.
- `~/.codex/auth.json` — OAuth credentials.
- Everything else under `~/.codex/` — sessions, history, sqlite state, caches,
  codex-managed system skills, plugin cache.

## Related

- The **codex plugin for Claude Code** (`codex@openai-codex`) is tracked via
  the `claude` package (`enabledPlugins` + `extraKnownMarketplaces` in
  `settings.json`).
- History note: `~/.codex/instructions.md` was deleted 2026-07-22 — it was a
  stale "lean-ctx" rules block mandating `ctx_*` MCP tools from a since-removed
  MCP server, actively steering codex toward nonexistent tools.
