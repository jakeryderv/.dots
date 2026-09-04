# zsh

`~/.zshrc`, tracked. The zsh counterpart of [`bash`](bash.md): history,
completion, keybindings, the `--zsh` hooks for fzf, starship and direnv, and
the plugins below, sourcing the shared [`shell`](shell.md) package for
everything else. The two rc files mirror each other section for section, so
switching shells changes the shell and nothing about the environment; the
plugins section is the one part bash has no counterpart for.

zsh itself comes from the distro, not the flake: a login shell is integrated
with the OS (`/etc/shells`, `chsh`, PAM), both shells release once every few
years so pinning buys nothing, and every distro's install is one line:

| Distro | Install |
| --- | --- |
| Pop / Debian | `sudo apt install zsh` |
| Arch | `pacman -S zsh` |
| NixOS | `programs.zsh.enable = true;` |

## Activate

```bash
dots apply shell zsh
```

Deploying `~/.zshrc` also sidesteps zsh's first-run configuration wizard,
which appears only when no rc file exists.

## Login shell

zsh is the login shell:

```bash
chsh -s /usr/bin/zsh        # apt already listed it in /etc/shells
```

Nothing else names a shell. [`ghostty`](ghostty.md) sets no `command`, and
[`herdr`](herdr.md) leaves `terminal.default_shell` empty, so both start
whatever `$SHELL` says; changing shells is `chsh` and a fresh session. The one
exception is herdr's floating popup, which runs a command rather than a shell
and so has to name `zsh` in `config.toml`.

To try a shell before committing, `command = zsh` in the ghostty overrides
starts it in that terminal alone while the login shell and every other entry
point (`~/.profile`, cron, the display manager, herdr panes) stay as they were;
reverting is one line. That is how zsh was evaluated here.

zsh login shells read `~/.zprofile`, not `~/.profile`, and Debian's zsh reads
`/etc/zsh/zshrc`, not the `/etc/zshrc` the Nix installer writes its hook into.
So a zsh login shell inherits neither the Nix profile nor anything `~/.profile`
set. `env.sh` covers the first by sourcing the Nix profile script itself when
`PATH` lacks it; the second matters only for a graphical session that relied on
`~/.profile` for `PATH`, which is the thing to check after `chsh`.

## Completions from the flake

zsh finds completions on `fpath`. The rc file prepends the profile's
`share/zsh/site-functions`, which is where every flake tool that ships one
(gh, rg, fd, bat, uv, cargo, rustup, ...) installs it, so nothing is listed
per tool.

## Plugins

Five, all from [`flake.nix`](nix.md) rather than a plugin manager: one
manager, one lock, and `nix profile upgrade` updates them with everything
else. The rc file sources each from `~/.nix-profile/share` behind a guard, so
a machine without the flake gets plain zsh, not an error.

| Plugin | Does | Without it |
| --- | --- | --- |
| `zsh-fzf-tab` | Tab completes through fzf, with group headers from the completion system's descriptions | Tab and Shift-Tab cycle matches, as bash does |
| `zsh-autosuggestions` | The rest of the last matching history line, greyed, after the cursor; Right or End accepts | nothing |
| `zsh-syntax-highlighting` | Colours the command line as it is typed; red means it will not run | nothing |
| `zsh-history-substring-search` | Up/Down walk history filtered by the typed text, matched anywhere in the line | the builtin prefix search, which is bash's behaviour |
| `zsh-completions` | Extra completion definitions, installed into the profile's `site-functions` | fewer commands complete |

Load order is fixed by the plugins' own READMEs and lives in one section of
the rc file: fzf-tab after `compinit` and before anything that wraps widgets,
syntax-highlighting before history-substring-search. `zsh-completions` has no
line in the rc file at all; `fpath` already covers where it installs.
