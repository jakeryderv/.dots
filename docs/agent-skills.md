# agent-skills

Skills authored here and shared by every coding agent (Claude Code, pi, and
anything else that reads `~/.agents/skills/`). Third-party skills installed
into `~/.agents/skills/` by skills.sh or a vendor CLI stay untracked; only
skills written in this repo live under `config/agent-skills/`.

## Linking

`~/.agents/skills/` is shared with the installers, so `dots.toml` links each
skill directory individually (never the parent), as `links` entries under one
package. Claude Code reads `~/.claude/skills/`, so every skill gets a second
entry linking it there — the same per-skill symlink the installer creates for
third-party skills. Pi reads `~/.agents/skills/` directly.

Adding a skill: create `config/agent-skills/<name>/SKILL.md`, add both `links`
entries to the `agent-skills` table, `dots apply agent-skills`.

## Tracked

| Skill | Purpose |
| --- | --- |
| `project-practices/` | Audit or scaffold a repo against the tiered project-practices reference (`reference.md` beside the skill). Day-one set plus trigger-gated additions. |
