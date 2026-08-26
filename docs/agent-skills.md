# agent-skills

Skills authored here and shared by every coding agent (Claude Code, pi, and
anything else that reads `~/.agents/skills/`). Third-party skills installed
into `~/.agents/skills/` by skills.sh or a vendor CLI stay untracked; only
skills written in this repo live under `home/agents/skills/`.

## Linking

`~/.agents/skills/` is shared with the installers, so the manifest links each
skill directory individually (never the parent). Claude Code reads
`~/.claude/skills/`, so every skill gets a second row linking it there — the
same per-skill symlink the installer creates for third-party skills. Pi reads
`~/.agents/skills/` directly.

Adding a skill: create `home/agents/skills/<name>/SKILL.md`, add both manifest
rows, `just apply agent-skills`.

## Tracked

| Skill | Purpose |
| --- | --- |
| `project-practices/` | Audit or scaffold a repo against the tiered project-practices reference (`reference.md` beside the skill). Day-one set plus trigger-gated additions. |
