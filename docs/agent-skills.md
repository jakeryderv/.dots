# agent-skills

| Source | Deploys to |
| --- | --- |
| `home/agents/skill-lock.json` | `~/.agents/.skill-lock.json` |

Tracks the lockfile for the shared agent-skill tree, and nothing else.

## What this is for

`~/.agents/skills/` holds skills that several agents share. Pi, agy and
opencode read that tree directly; Claude Code does not, so its entries appear
under `~/.claude/skills/` as relative symlinks into it.

None of those skills are tracked here. They are installed from upstream by
skills.sh or a vendor CLI, and `.skill-lock.json` is the record of where each
one came from — repo, git URL, path within it, and a folder hash:

```json
"gh": {
  "source": "cli/cli",
  "sourceUrl": "https://github.com/cli/cli.git",
  "skillPath": "skills/gh/SKILL.md",
  "skillFolderHash": "cc6ec474..."
}
```

Tracking the lockfile alone keeps the tree rebuildable without vendoring a
fork of anyone else's skill into this repo. Copying skill content here was
tried once and reverted: see the history note in [`claude`](claude.md).

## Known gap

`use-railway` is installed in the tree but absent from the lockfile — a vendor
installer placed it (it also appears under `~/.copilot/skills/` and
`~/.cursor/skills/`) without registering it. Re-run that installer to restore
it; the lockfile will not tell you how.

## Runtime writes

skills.sh rewrites this file whenever a skill is installed or removed, so it
turns up dirty in `git status` after any skill change. Commit when the change
is intentional. The same applies to `home/claude/settings.json`, which Claude
Code rewrites at runtime.

If a skill install ever leaves `~/.agents/.skill-lock.json` a real file rather
than a symlink, skills.sh writes atomically and replaced the link; re-run
`just apply agent-skills` and check whether the tool needs a different
tracking approach.
