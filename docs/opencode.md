# opencode

[OpenCode](https://opencode.ai) terminal coding agent. Global configuration
deploys to `~/.config/opencode/` using `tree` mode: real directories containing
one symlink per tracked file. OpenCode's dependencies and Herdr's integration
scripts live beside the links. The CLI is installed separately; `dots apply`
does not install or upgrade it. Configuration checked with OpenCode 1.18.31.

See the root [README](../README.md) for shared deployment mechanics.

## Files

| File | Purpose |
| --- | --- |
| `opencode.jsonc` | Main configuration; currently just its schema, inheriting defaults |
| `tui.jsonc` | Carbonfox theme and Herdr's selected-session plugin registration |

No model, provider credentials, permission overrides, custom agents, commands,
or MCP servers are declared here. Project-specific configuration can override
the global configuration. Schemas:
[main config](https://opencode.ai/config.json) and
[TUI config](https://opencode.ai/tui.json).

## Activate

Install OpenCode using its [installation guide](https://opencode.ai/docs/),
then install [Herdr](herdr.md) and its OpenCode integration before starting the
TUI with this config:

```bash
herdr integration install opencode
herdr integration status
dots plan opencode
```

The integration creates `opencode.jsonc` and/or `tui.jsonc` on a fresh machine.
If `dots plan` reports real-file conflicts, compare those files with
`config/opencode/`, preserve any wanted settings, and move the local files to
unused backup names. `dots apply` deliberately refuses to overwrite them.

```bash
dots apply opencode
dots status opencode
opencode debug config
opencode auth list
```

Authenticate per machine with `opencode auth login` if needed. **Quit and
restart OpenCode after changing configuration**; running sessions keep their
already-loaded settings. `opencode debug config` checks the main resolved
configuration; start the TUI to check its separate config and plugin loading.

## Appearance and local preferences

`tui.jsonc` selects the built-in `carbonfox` theme to match
[Ghostty](ghostty.md) and the rest of the terminal setup.

The other existing UI preferences are saved by OpenCode in
`~/.local/state/opencode/kv.json`. They are not exposed as declarative settings
in the current TUI schema, so recreate them through the UI on a new machine:

- Hide the sidebar, thinking, timestamps, scrollbar, and generic tool output.
- Show tool details and assistant metadata.
- Use word-wrapped diffs and enable animations.

Keep that mutable state file local. Model recents, favorites, and reasoning
variants in `~/.local/state/opencode/model.json` are also local selections,
not pinned defaults in this package.

## Herdr integration

Herdr installs and updates two files outside this repository:

| File under `~/.config/opencode/` | Role |
| --- | --- |
| `plugins/herdr-agent-state.js` | Auto-discovered plugin reporting working/blocked/idle state and native session IDs |
| `herdr-tui-session.js` | TUI plugin reporting which root conversation is selected in the pane |

The relative plugin path in `tui.jsonc` refers to the deployed config directory.
Both plugins activate only inside a Herdr environment. Reinstall/update them
with `herdr integration install opencode`; do not edit the generated scripts.
Any user-authored plugins belong in separate files.

After integration updates or settings changes, run `dots status opencode`.
If a tool replaces a symlink with a real file, review the new content, adopt
wanted changes into the repo, back up the local file, and reapply the package.

## Shared instructions and skills

OpenCode discovers the global instructions in `~/.claude/CLAUDE.md` and shared
skills under `~/.claude/skills/` and `~/.agents/skills/`. Those are managed by
the [claude](claude.md) and [agent-skills](agent-skills.md) packages or their
respective third-party installers, rather than duplicated here.

## Machine-local files

OpenCode owns `node_modules/`, package manifests/lockfiles, and its generated
`.gitignore` under `~/.config/opencode/`. Tree mode keeps them outside the repo;
the root `.gitignore` also excludes copies of these and Herdr's two scripts.

Credentials (`~/.local/share/opencode/auth.json`), sessions, logs, caches,
prompt history, and UI/model state remain in OpenCode's data, cache, and state
directories. `opencode debug paths` prints the machine's actual locations.
