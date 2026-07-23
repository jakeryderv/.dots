# agent-skills

Portable coding-agent skills, managed as one GNU Stow package. This directory
is the source of truth for shared skills across Codex, Claude Code, Pi, and
OpenCode.

The canonical tree deploys to `~/.agents/skills/`. Codex, Pi, and OpenCode read
that standard location directly. Claude Code uses the compatibility symlinks
under `~/.claude/skills/`; every one resolves back to the same canonical tree.

## Skill manifest

| Skill | Upstream / provenance |
| --- | --- |
| `agents-sdk` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `cloudflare` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `cloudflare-email-service` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `cloudflare-one` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `cloudflare-one-migrations` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `durable-objects` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `playwright-cli` | [`microsoft/playwright-cli`](https://github.com/microsoft/playwright-cli/tree/main/skills/playwright-cli) |
| `sandbox-sdk` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `systematic-debugging` | [`obra/superpowers`](https://github.com/obra/superpowers) 6.1.1 (MIT); salvaged on plugin removal, descriptions softened, cross-refs removed |
| `turnstile-spin` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `use-railway` | Railway CLI agent tooling; embedded caller revision `1.3.6` |
| `verification-before-completion` | [`obra/superpowers`](https://github.com/obra/superpowers) 6.1.1 (MIT); salvaged on plugin removal, descriptions softened, cross-refs removed |
| `web-perf` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `workers-best-practices` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |
| `wrangler` | [`cloudflare/skills`](https://github.com/cloudflare/skills) |

## Agent wiring

| Agent | Shared-skill discovery |
| --- | --- |
| Codex | Reads `~/.agents/skills/` directly; `.codex/skills/.system/` remains Codex-owned. |
| Claude Code | Reads compatibility links under `~/.claude/skills/`. Claude-only and plugin skills remain there separately. |
| Pi | Reads `~/.agents/skills/` directly; `~/.pi/agent/skills/` is reserved for Pi-only skills. |
| OpenCode | Reads `~/.agents/skills/` directly; `~/.config/opencode/skills/` is reserved for OpenCode-only skills. |

OpenCode also scans `~/.claude/skills/` by default. The tracked Bash alias sets
`OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` only for OpenCode so it does not load
the Claude compatibility mirror as a second copy.

The Bash aliases for the four agents also set a distinct
`PLAYWRIGHT_CLI_SESSION` value. This keeps simultaneous agents from sharing
the same default browser session while still sharing the CLI and browser
downloads.

## Install

Stow the shared package:

```bash
dots stow agent-skills --apply
```

Install the Playwright CLI runtime separately when browser automation is
wanted:

```bash
bash _helpers/install-playwright-cli.sh
```

On an existing machine migrating from per-agent copies, remove those copies
before stowing so GNU Stow can create the canonical links. The repository
validator catches any copies that remain.

## Ownership boundaries

Only portable Agent Skills belong here. Keep these in their native agent
packages or tool-managed directories:

- Codex system skills, plugins, configuration, and tool-managed instructions.
- Claude-only skills, plugins, and settings.
- Pi packages, extensions, settings, prompts, and Pi-only skills.
- OpenCode agents, commands, plugins, settings, and OpenCode-only skills.

Do not run agent-specific skill installers against all four live directories.
Stage upstream updates, review the diff once in `.agents/skills/`, then update
the canonical copy and its manifest entry. Preserve upstream skill contents;
package maintenance documentation belongs in this README rather than inside an
individual skill.

## Verify

Validate the tracked structure in CI or before stowing:

```bash
bash _helpers/verify-agent-skills.sh
```

After stowing, also validate the live paths and absence of duplicate local
copies:

```bash
bash _helpers/verify-agent-skills.sh --live
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
