# bash

`~/.bashrc`, tracked, replacing the distro's stock file. It holds what only
bash understands — history and `shopt`, readline bindings, bash-completion,
and the `--bash` hooks for fzf, starship and direnv — and sources the shared
[`shell`](shell.md) package for everything else.

Load order, from the file itself:

```
env.sh → history/shopt → completion + readline → functions.sh → aliases.sh
      → keybindings → fzf/starship/direnv hooks → local.sh
```

`local.sh` is last so it can override anything before it. The tool hooks come
after our keybindings because they install bindings of their own (fzf takes
Ctrl-R, Ctrl-T and Alt-C; ours is Ctrl-F).

## Activate

```bash
dots apply shell bash
```

`~/.bashrc` is a `link` entry, so `dots apply` refuses to replace an existing
real file: move the distro's aside first (`mv ~/.bashrc ~/.bashrc.pre-dots`).
`~/.profile` stays the distro's and untracked — it sources `~/.bashrc` for
login shells and gives the graphical session its `PATH`.

## Completions

bash-completion loads a command's completion on first Tab from user and system
data directories. Official apt/.deb packages supply system completions;
release archives and generated completions go under
`${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions`.
See [the software inventory](software.md#completions-manuals-and-integrations)
for the CLI completion sources.

nvm is loaded by the shared environment file; its own `bash_completion` is
sourced afterward by `bashrc`.
