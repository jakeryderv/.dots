# agent-skills

Personal and forked coding-agent skills, managed as one the manifest deployer package.
Only skills authored or modified here are tracked; **third-party skills are
not vendored** — they're installed and updated by [skills.sh](https://skills.sh)
or their own vendor CLI (see below), keeping this package purely "my config"
no matter how many tools ship skills.

The canonical tree deploys to `~/.agents/skills/` — the cross-agent standard
location — with Claude Code compatibility links under `~/.claude/skills/`.
skills.sh and the vendor CLIs use the same layout, so tracked and installed
skills coexist in the same live directories.

## Tracked skills

| Skill | Provenance |
| --- | --- |
| `systematic-debugging` | [`obra/superpowers`](https://github.com/obra/superpowers) 6.1.1 (MIT); salvaged on plugin removal, descriptions softened, cross-refs removed |
| `verification-before-completion` | [`obra/superpowers`](https://github.com/obra/superpowers) 6.1.1 (MIT); salvaged on plugin removal, descriptions softened, cross-refs removed |

Claude-only skills (`project-status`, `suggest-optimization`) live in the
`claude` package instead. OpenCode-only (`uv-python`) lives in `opencode`.

## Third-party skills (not tracked)

Installed globally per machine; re-run on a fresh machine after installing
the CLIs:

```bash
# Cloudflare platform skills (11): agents-sdk, cloudflare, durable-objects,
# sandbox-sdk, wrangler, workers-best-practices, web-perf, turnstile-spin,
# cloudflare-one, cloudflare-one-migrations, cloudflare-email-service
npx skills add -g cloudflare/skills --skill '*' -y

# Playwright browser automation (repo also ships an internal 'dev'
# maintenance skill — excluded)
npx skills add -g microsoft/playwright-cli --skill playwright-cli -y

# Railway (installs via its own CLI, not skills.sh; also handles MCP setup
# via `railway setup agent`)
railway skills install

# gh CLI invocation patterns (installs via gh's own CLI; `gh skill` is a
# preview subsystem, so the command surface may drift). `--agent universal`
# targets the canonical ~/.agents/skills; gh writes one agent directory only,
# so the Claude compat link is made by hand — unlike skills.sh, which links
# every per-agent path itself.
gh skill install cli/cli gh --agent universal --scope user
ln -s ../../.agents/skills/gh ~/.claude/skills/gh
```

Maintenance:

```bash
npx skills ls -g       # audit everything installed, per agent, with source
npx skills update -g   # refresh third-party skills from upstream
railway skills update  # railway skill is updated by its own CLI
gh skill update gh     # gh skill is updated by its own CLI
```

skills.sh and the railway CLI write canonical copies into `~/.agents/skills/`
and link or copy per-agent compatibility paths (`~/.claude/skills/`,
`~/.codex/skills/`, `~/.config/opencode/skills/`, ...). `skills ls -g` also
lists this package's tracked skills as `Source: local` — a useful whole-system
audit.

`gh skill list` is **not** a substitute for that audit: it reports only what it
installed plus real directories, and skips symlinked skill dirs entirely — so
this package's tracked skills are invisible to it, as are the skills.sh
compatibility links.

## Agent wiring

| Agent | Shared-skill discovery |
| --- | --- |
| Claude Code | Reads `~/.claude/skills/` (links back to `~/.agents/skills/`). Claude-only and plugin skills remain there separately. |
| Codex | Reads `~/.agents/skills/` directly; `.codex/skills/.system/` remains Codex-owned; railway adds a copy under `~/.codex/skills/`. |
| Antigravity (agy) | Reads `~/.agents/skills/` directly (confirmed via `skills ls -g` agent detection). |
| Pi | Reads `~/.agents/skills/` directly; `~/.pi/agent/skills/` is reserved for Pi-only skills. |
| OpenCode | Reads `~/.agents/skills/` directly; `~/.config/opencode/skills/` is reserved for OpenCode-only skills. |

OpenCode also scans `~/.claude/skills/` by default. The tracked Bash alias sets
`OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` only for OpenCode so it does not load
the Claude compatibility mirror as a second copy.

The Bash aliases for the agents also set a distinct `PLAYWRIGHT_CLI_SESSION`
value. This keeps simultaneous agents from sharing the same default browser
session while still sharing the CLI and browser downloads.

## Install

Deploy the tracked package, then install third-party skills:

```bash
just apply agent-skills
# then run the third-party install commands above
```

This package and the `claude` package both link into `~/.claude/skills/`. Both
are `tree` rows, so each links only its own tracked files and the two never
interact — no ordering or special flags required.

Install the Playwright CLI runtime separately when browser automation is
wanted:

```bash
bash tools/install-playwright-cli.sh
```

## Ownership boundaries

- Tracked here: portable skills that are personally authored, or forked with
  local modifications (no live upstream manages them).
- skills.sh / vendor CLIs: everything third-party. If a tracked skill gains a
  managed upstream, drop it from the package and add its install command
  above.
- Agent-specific skills stay in their agent's package (`claude`, `opencode`,
  `pi`).
- Codex system skills, plugins, and tool-managed instructions remain
  tool-owned; never track them.

## Verify

Validate the tracked structure in CI or before deploying:

```bash
bash tools/verify-agent-skills.sh
```

After deploying, also validate the live paths:

```bash
bash tools/verify-agent-skills.sh --live
```

For a Playwright smoke test:

```bash
playwright-cli --version
playwright-cli open https://example.com
playwright-cli snapshot
playwright-cli close
```

Use `--headed` with `open` when a visible browser is useful. The CLI is
headless by default.
