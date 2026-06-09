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
| **`bash`**     | sourced, *not* stowed       | Modular bash config (see `bash/README.md`)  |

Directories prefixed with `_` are **not** stow packages — just stored in the repo:

| Dir           | Purpose                                            |
| ------------- | -------------------------------------------------- |
| `_helpers`    | Install/update scripts for tools (see below)       |
| `_wallpapers` | Wallpaper images                                   |

## Setup on a new machine

```bash
sudo apt install stow            # if not already installed
git clone <repo> ~/.dots
cd ~/.dots

# Symlink the packages you want (run from ~/.dots; target is $HOME)
stow alacritty ghostty kitty nvim tmux starship qutebrowser fonts scripts

# bash is sourced, not stowed — add this to ~/.bashrc:
#   [ -f "$HOME/.dots/bash/_init_.sh" ] && source "$HOME/.dots/bash/_init_.sh"
cp bash/local.sh.example bash/local.sh   # then edit for this machine
```

To remove a package's symlinks: `stow -D <package>`.

## Helper scripts (`_helpers/`)

| Script                          | Installs                       |
| ------------------------------- | ------------------------------ |
| `install-fzf.sh`                | fzf (cloned to `~/.fzf`)       |
| `install-glow.sh`               | glow (markdown renderer for `llm.sh`) |
| `install-lazygit.sh`            | lazygit                        |
| `install-qutebrowser.sh`        | qutebrowser (from source, via `uv` + `mkvenv.py`; `--keep` for fast update) |
| `install-tmux-sessionizer.sh`   | tmux-sessionizer               |
| `update-nvim.sh`                | latest Neovim (AppImage)       |

## Tools this config expects

- **nvim** (AppImage) — primary editor
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
- pi-coding-agent
- hermes
- antigravity
