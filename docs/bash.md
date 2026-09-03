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

## Completions from the flake

bash-completion loads a command's completion on first Tab from
`$XDG_DATA_DIRS/bash-completion/completions`. The Nix profile script puts
`~/.nix-profile/share` on `XDG_DATA_DIRS`, so every flake tool that ships a
completion (gh, rg, fd, bat, uv, cargo, ...) is covered without being listed.
