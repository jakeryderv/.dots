# pi

Global config for the [Pi](https://pi.dev) coding agent, managed as a GNU Stow package.

Mirrors `~/.pi/agent/`. Only **user-authored** config is tracked here:

| Tracked | Tool-managed (NOT tracked) |
|---------|----------------------------|
| `settings.json` | `auth.json` — secrets/OAuth tokens |
| `themes/`       | `sessions/` — conversation history |
| `skills/`       | `bin/` — Pi's managed binaries |
| `extensions/`   |  |

## Activate

`~/.pi/agent/` already exists (Pi writes to it), so `settings.json` will conflict
on first stow. Back up the live file, then stow:

```bash
mv ~/.pi/agent/settings.json ~/.pi/agent/settings.json.bak   # safety net
cd ~/.dots && stow pi
```

This symlinks:
- `~/.pi/agent/settings.json` → this repo
- `~/.pi/agent/{themes,skills,extensions}/` → this repo (whole dirs, since they didn't exist)

Verify: `ls -l ~/.pi/agent/settings.json` should show a symlink into `~/.dots/pi`.

Once happy: `rm ~/.pi/agent/settings.json.bak`

## Unstow

```bash
cd ~/.dots && stow -D pi
```

## Notes

- **Secrets never live here.** API keys go in your shell env (`ANTHROPIC_API_KEY`)
  or stay in the untracked `~/.pi/agent/auth.json`. See repo-root `.gitignore`.
- **`settings.json` churn:** Pi rewrites this file (e.g. `lastChangelogVersion`) when
  you use `/settings` or it sees a new release. Since it's symlinked, those edits land
  here — commit the real ones, ignore the version bump.
- **Hot reload:** themes/extensions edited here apply live in Pi via `/reload`
  (themes refresh automatically).
- **Per-project config** belongs in each project's own `.pi/`, not this repo.
