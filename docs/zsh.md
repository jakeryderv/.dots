# zsh

`~/.zshrc`, tracked. The zsh counterpart of [`bash`](bash.md): history,
completion, keybindings, the `--zsh` hooks for fzf, starship and direnv, and
the plugins below, sourcing the shared [`shell`](shell.md) package for
everything else. The two rc files mirror each other section for section, so
switching shells changes the shell and nothing about the environment; the
plugins section is the one part bash has no counterpart for.

zsh itself comes from the distro: a login shell is integrated
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

zsh login shells read `~/.zprofile`, not `~/.profile`. The tracked rc file
loads `env.sh` to set up the shared PATH. Check the graphical session after
`chsh` if it previously relied on `~/.profile` for environment setup.

## Completions

zsh finds completions on `fpath`. The rc file includes the user directory
`${XDG_DATA_HOME:-~/.local/share}/zsh/site-functions` for upstream tools,
`~/.local/share/zsh/plugins/zsh-completions/src` for the upstream plugin,
`/usr/share/zsh/site-functions` (used by Glow's apt package),
and Zsh's system vendor directories for apt/.deb packages.
No per-tool source hooks are needed. See the
[software inventory](software.md#completions-manuals-and-integrations).

nvm is loaded by the shared environment file. Its Zsh completion comes from
the existing `zsh-completions` package.

## Plugins

Five official repository clones under
`${XDG_DATA_HOME:-~/.local/share}/zsh/plugins`, each checked out at a release
tag. The [software inventory](software.md#zsh-plugins) records installation,
versions and updates. The rc file loads each behind a guard, so a missing
plugin leaves the corresponding feature disabled.

| Plugin | Does | Without it |
| --- | --- | --- |
| `fzf-tab` | Tab completes through fzf, with group headers from the completion system's descriptions | Tab and Shift-Tab cycle matches, as bash does |
| `zsh-autosuggestions` | The rest of the last matching history line, greyed, after the cursor; Right or End accepts | nothing |
| `zsh-syntax-highlighting` | Colours the command line as it is typed; red means it will not run | nothing |
| `zsh-history-substring-search` | Up/Down walk history filtered by the typed text, matched anywhere in the line | the builtin prefix search, which is bash's behaviour |
| `zsh-completions` | Extra completion definitions from its `src` directory | fewer commands complete |

Load order is fixed by the plugins' own READMEs and lives in one section of
the rc file: fzf-tab after `compinit` and before anything that wraps widgets,
syntax-highlighting before history-substring-search. `zsh-completions` has no
source line; its `src` directory is added to `fpath` before `compinit`.
