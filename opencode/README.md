# opencode

Global config for the [opencode](https://opencode.ai) coding agent, managed as a GNU Stow package.

Mirrors `~/.config/opencode/`. Only **user-authored** config is tracked here;
secrets and tool-managed machinery are left in place and ignored.

| Tracked | Tool-managed (NOT tracked) |
|---------|----------------------------|
| `opencode.json` — OpenAI defaults, OpenRouter agents, Ollama local models, permissions, MCP servers | `node_modules/`, `package*.json`, `bun.lock` — plugin machinery (opencode regenerates these) |
| `AGENTS.md` — global rules | `~/.local/share/opencode/` — `auth.json`, `account.json`, `opencode.db`, state (separate data dir) |
| `commands/` — custom `/commands` (generic `test`, `lint`, `cov`; plus `interview`, `council`, `model-health`, `tune-config`, `tmux-logs`) | |
| `agents/` — subagents (`explore`, `review`, `plan`, `tdd`, `council-{code,cli,vision,reason,general}`) + `config-tuner` | |
| `skills/` — on-demand instruction sets for project-specific workflows (`uv-python`) | |
| `themes/` — custom TUI theme (`carbonfox-jake`); `tui.json` selects it | |
| `modes/`, `tools/` *(if added later)* | |

Secrets live in `~/.local/share/opencode/`, not in the config dir, so nothing
tracked here contains credentials. `opencode.json` itself uses `{env:VAR}` /
`{file:...}` references for any secret values (none currently — it just defines
a local Ollama provider).

## Activate

`~/.config/opencode/` may already contain tool-managed files, so
the live `opencode.json` will conflict on first stow. Move it into the repo,
then stow links it back:

```bash
mkdir -p ~/.dots/opencode/.config/opencode
mv ~/.config/opencode/opencode.json ~/.dots/opencode/.config/opencode/
cd ~/.dots && stow opencode
```

To remove the symlink: `cd ~/.dots && stow -D opencode`.

## Validate

Run `dots doctor` to validate the resolved config when opencode is installed,
along with the repository and Stow health checks.
