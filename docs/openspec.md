# openspec

Global config for the [OpenSpec](https://github.com/Fission-AI/OpenSpec) CLI
(`@fission-ai/openspec`), the spec/change-management layer shared by Claude
Code, Codex, and Antigravity. Replaced the superpowers plugin as the planning
workflow on 2026-07-23.

## Tracked

| File | Purpose |
| --- | --- |
| `.config/openspec/config.json` | Workflow profile: `custom` = core six (propose, explore, apply, update, sync, archive) + verify, onboard, bulk-archive |

The file also carries a telemetry block (`noticeSeen`, random `anonymousId`) —
harmless to publish, write-once, and re-generated if absent. Verified the CLI
writes through the symlink without breaking it (`openspec config set` edits in
place).

## Not tracked

Everything else is per-repo, by design: `openspec init` in a repository
generates that repo's `openspec/` dir plus agent-local skills/commands
(`.claude/`, `.codex/`, `.agent/`), all committed to the repo itself.
OpenSpec touches no agent global configs.

## Fresh machine

```bash
npm install -g @fission-ai/openspec
just apply openspec
```

`openspec update` in each repo after CLI upgrades to regenerate the
per-repo skills/commands.
