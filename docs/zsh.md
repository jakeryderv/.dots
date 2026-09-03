# zsh

`~/.zshrc`, tracked. The zsh counterpart of [`bash`](bash.md): history,
completion, keybindings, and the `--zsh` hooks for fzf, starship and direnv,
sourcing the shared [`shell`](shell.md) package for everything else. The two
rc files mirror each other section for section, so switching shells changes
the shell and nothing about the environment.

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

**Evaluate before switching.** `command = zsh` in the ghostty overrides starts
zsh in the terminal that matters while the login shell stays bash, so every
other entry point (`~/.profile`, cron, the display manager) is untouched and
reverting is one line. Once it sticks:

```bash
chsh -s /usr/bin/zsh        # apt already listed it in /etc/shells
```

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
