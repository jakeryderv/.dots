# scripts

Personal scripts. Deployed to `~/.local/bin/` (must be on your `PATH`).

See the root [README](../README.md) for shared deployment mechanics.

## Completions

Each script ships a bash completion in
`.local/share/bash-completion/completions/`, named after the command. They are
autoloaded on first Tab rather than at shell startup, so they cost nothing until
used and disappear along with the script if this package is unlinked. They need
the `bash-completion` package, which `shell/completions.sh` already sources; if
it is missing, Tab silently falls back to filename completion.

## Activate

```bash
cd ~/.dots && just apply scripts
```

Both rows are `tree` mode, which matters here. A single symlink at
`~/.local/bin` or `~/.local/share/bash-completion/completions` would mean
anything else installing there — such as
[`tools/install-npm-globals.sh`](../tools/README.md) — writes a
third-party file straight into the repo. As `tree` rows the targets stay real directories
holding one symlink per tracked file; `~/.local/bin` currently has 76 entries,
of which four are ours.

## Scripts

### `tmux-sessionizer`

fzf a project directory and attach or switch to a tmux session for it. Bound to
`prefix + f` in [`tmux`](tmux.md) and `Ctrl-F` in `shell/keybinds.sh`.

Vendored from ThePrimeagen/tmux-sessionizer at commit `7edf8211`, which is
unmaintained. It was previously fetched by an installer against a pinned commit
and checksum; keeping the file here removes that indirection and puts it under
the same ShellCheck and shfmt gates as the rest of `bin/`. The only local
changes are formatting and the fixes those gates required, each marked
`vendor fix` inline.

Search paths come from `~/.config/tmux-sessionizer/tmux-sessionizer.conf`, which
is **not tracked** — a fresh machine falls back to upstream's defaults
(`~/ ~/personal ...`), which are wrong for this setup.

### `gconf`

Inspects and edits git config by scope, rendering `section.key = value` with the
source file in an aligned left column.

```bash
gconf               # brief usage summary
gconf g             # global list
gconf g e           # edit ~/.gitconfig
gconf g o           # global list, annotated with the file each value came from
gconf local edit    # long forms work too
gconf a             # report: one table per scope, each with origins
NO_COLOR=1 gconf a  # standard no-color convention
```

Scopes are `l|local`, `g|global`, and `s|system`; each takes an action of
`l|list` (default), `e|edit`, or `o|origin`.

`a|all` is a report rather than a scope, so it takes no action: it prints a
table per scope, always annotated with origins. Origins still earn their column
inside a single scope, since `include.path` and `includeIf` pull in other files.
A scope that does not apply — no repository, no `/etc/gitconfig` — is noted in
place and the rest of the report continues.

A bare `gconf` prints the summary rather than picking a scope for you.
`--color=always|never|auto` overrides the tty check.

### `bs`

A composable `ls` replacement — a self-contained bash pipeline (gather → filter
→ sort → transform → format) with no dependencies beyond coreutils (`fzf`/`bat`
optional, used only by the interactive/preview modes).

Highlights:

- **Filters** — hidden/dirs/files/exec/links, glob/extension match, `--exclude`,
  min/max size, `--today`/`--week`.
- **Sorting** — time (default), size, name, extension; `--reverse`,
  `--group` (hidden first).
- **Output** — long, symlink targets, Nerd Font `--icons`, `--relative` times,
  `--tree` (with `-R`), `--json`, `--total`, `--summary`, `--no-color`.
- **Interactive** — `--fzf`, `--multi`, `--preview` (bat), `--edit` (open in
  `$EDITOR`).
- **Other** — `-R`/`--depth N`, `--git` status column, `--watch [N]`, and
  `--preset NAME` presets from `${XDG_CONFIG_HOME:-~/.config}/bs/config`.

Run `bs -h` for the full option list and a sample preset config.

### `ai`

llm helpers for the terminal: each subcommand gathers context — a man page,
`--help` output, grep hits, a file, stdin — hands it to
[`llm`](https://llm.datasette.io), and renders the markdown that comes back
through [glow](../tools/README.md).

```bash
ai man tar -- extract a single file    # explain a man page
ai help just -- what is --dry-run      # explain a command's --help output
make 2>&1 | ai why                     # explain an error
ai how convert webm to mp4             # intent → command
git log --oneline -50 | ai sum         # summarize stdin
ai grep TODO notes.md what is left     # grep, then ask about the hits
ai chunk big.log why did it fail       # map/reduce over a file too big to send
ai ask "..."                           # general question, stdin optional
ai ml "..."                            # local model, ML system prompt
ai code python retry decorator         # one fenced code block, nothing else
```

`-m MODEL` passes a model through to `llm`; `--renderer glow|bat|cat` overrides
the renderer for one call (`cat` when piping the output somewhere else).
`AI_RENDERER` sets the default — `local.sh` is the place for it. `ai -h` lists
the remaining environment knobs (`AI_GREP_CONTEXT`, `AI_CHUNK_SIZE`,
`AI_ML_MODEL`, and the prompt-wrapper overrides).

These used to be bash functions in [`shell/llm.sh`](../shell/README.md); as a
script they also work from nvim (`:%!ai sum`), tmux, cron, and other scripts.
`shell/llm.sh` still defines the short names — `manai`, `howto`, `summarize`,
`why`, `ask`, and friends. `helpai` remains a function on purpose: only the
shell that defines a function, alias, or builtin can capture its `--help`
output, so it captures the text and pipes it to `ai help -`.
