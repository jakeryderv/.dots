# dotfiles

My personal dotfiles for Pop!_OS / bash, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Stowing a package symlinks its contents into place — e.g.
`alacritty/.config/alacritty/alacritty.toml` → `~/.config/alacritty/alacritty.toml`.

## Layout

| Package        | Deploys to                  | What it is                          |
| -------------- | --------------------------- | ----------------------------------- |
| `alacritty`    | `~/.config/alacritty/`      | Alacritty terminal config           |
| `ghostty`      | `~/.config/ghostty/`        | Ghostty terminal config             |
| `kitty`        | `~/.config/kitty/`          | Kitty terminal config               |
| `wezterm`      | `~/.config/wezterm/`        | WezTerm terminal config             |
| `nvim`         | `~/.config/nvim/`           | Neovim config                       |
| `tmux`         | `~/.tmux.conf`              | tmux config                         |
| `starship`     | `~/.config/starship.toml`   | Starship prompt                     |
| `qutebrowser`  | `~/.config/qutebrowser/`    | qutebrowser config                  |
| `opencode`     | `~/.config/opencode/`       | opencode agent config (see `opencode/README.md`) |
| `fonts`        | `~/.local/share/fonts/`     | Nerd Fonts                          |
| `scripts`      | `~/.local/bin/`             | Personal scripts                    |
| `pi`           | `~/.pi/agent/`              | Pi coding-agent config (see `pi/README.md`) |

Directories prefixed with `_` are **not** stow packages — just stored in the repo
(the root `.stow-local-ignore` keeps them from ever being symlinked):

| Dir           | Purpose                                            |
| ------------- | -------------------------------------------------- |
| `_bash`       | Modular bash config, *sourced* not stowed (see `_bash/README.md`) |
| `_helpers`    | Install/update scripts for tools (see below)       |
| `_wallpapers` | Wallpaper images                                   |

> **Note:** `.gitignore` does **not** affect Stow. To stop Stow from symlinking
> generated state or local-only files, add them to `.stow-local-ignore`.

## Setup on a new machine

This repo is written for **Pop!_OS / Debian** (apt, GNU coreutils, Linux
x86_64). Package names differ from other distros — notably `fd-find` provides
the `fdfind` binary and `bat` provides `batcat`; the bash config accounts for
these. Helper scripts in `_helpers/` assume Linux x86_64 + apt/sudo.

```bash
sudo apt install stow            # if not already installed
git clone <repo> ~/.dots
cd ~/.dots

# Symlink the packages you want. --dir/--target are explicit so this works
# regardless of where the repo lives or your current directory.
stow --dir "$HOME/.dots" --target "$HOME" \
  alacritty ghostty kitty wezterm nvim tmux starship qutebrowser fonts scripts pi

# _bash is sourced, not stowed — add this to ~/.bashrc:
#   [ -f "$HOME/.dots/_bash/_init_.sh" ] && source "$HOME/.dots/_bash/_init_.sh"
cp _bash/local.sh.example _bash/local.sh   # then edit for this machine
```

### Managing packages

All commands assume `--dir "$HOME/.dots" --target "$HOME"` (omitted below for
brevity; add them, or run from `~/.dots` where `$HOME` is the default target).

```bash
stow -n -v <pkg>     # dry-run: preview links without touching the filesystem
stow <pkg>           # create symlinks
stow -R <pkg>        # restow (re-link after adding/removing files in a package)
stow -D <pkg>        # delete this package's symlinks
stow --adopt <pkg>   # adopt pre-existing real files into the repo, then link
```

If Stow reports a conflict ("existing target is neither a link nor a
directory"), the target already exists as a real file. Either back it up and
remove it, or use `--adopt` to pull it into the repo (then `git diff` to review
what was adopted before keeping it).

### Prompt, terminals & fonts

A few things need activation beyond `stow`:

- **Starship** — stowing installs `starship.toml` but does not enable the
  prompt. Install starship, then enable it in `_bash/local.sh`
  (`eval "$(starship init bash)"`).
- **Fonts** — after `stow fonts`, refresh the cache and confirm:

  ```bash
  fc-cache -f ~/.local/share/fonts
  fc-match '0xProto Nerd Font Mono'
  ```

- **tmux** — needs a modern tmux plus external tooling not managed by stow:
  install `fzf` and `tmux-sessionizer` (see `_helpers/`), clone TPM to
  `~/.tmux/plugins/tpm`, reload (`prefix + r`), then install plugins
  (`prefix + I`).

## Helper scripts (`_helpers/`)

| Script                          | Installs                       |
| ------------------------------- | ------------------------------ |
| `install-fzf.sh`                | fzf (cloned to `~/.fzf`)       |
| `install-glow.sh`               | glow (markdown renderer for `llm.sh`) |
| `install-lazygit.sh`            | lazygit                        |
| `install-qutebrowser.sh`        | qutebrowser (from source, via `uv` + `mkvenv.py`; `--keep` for fast update) |
| `install-tmux-sessionizer.sh`   | tmux-sessionizer               |
| `update-nvim.sh`                | latest Neovim (official `.tar.gz` build to `/opt`) |

## Tools this config expects

- **nvim** (official `.tar.gz` build; requires **Neovim ≥ 0.12** — see `nvim/.config/nvim/README.md`) — primary editor
- **fzf** — fuzzy finder (`~/.fzf`)
- **tmux-sessionizer** — tmux session jumper (bound to `Ctrl-f`)
- **starship** — prompt (starship.rs)
- **bat** (`batcat`) — better `cat`
- **eza / lsd** — better `ls` *(optional)*
- **zoxide / fd** — smarter `cd` / `find` *(optional)*
- **llm** — CLI LLM access (used by `bash/llm.sh`; ollama for free local models)
- **glow** — markdown rendering for `llm.sh` output
- **chafa** — terminal image rendering (multi-protocol)

## Implement next/later

- vscode
- hermes
- antigravity
