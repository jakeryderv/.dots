# dotfiles

My personal dotfiles for Pop!_OS / bash, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Stowing a package symlinks its contents into place — e.g.
`alacritty/.config/alacritty/alacritty.toml` → `~/.config/alacritty/alacritty.toml`.

## Conventions

- **Every package is self-documenting** — each directory has its own `README.md`
  covering what it is, where it deploys, how to activate it, and any external
  dependencies. This root file is just an index; details live in the package
  READMEs linked below.
- **READMEs live at the package root** (`ghostty/README.md`, not
  `ghostty/.config/ghostty/README.md`) and are never symlinked into `$HOME`
  (the `README[.]md` entry in `.stowrc` catches them at any depth).
- `_helpers/verify-readmes.sh` checks that every package/asset/tooling dir has a README.

## Packages

| Package | Deploys to | What it is |
| --- | --- | --- |
| [`git`](git/README.md) | `~/.gitconfig` | Global Git behavior, aliases, and defaults |
| [`alacritty`](alacritty/README.md) | `~/.config/alacritty/` | Alacritty terminal config |
| [`ghostty`](ghostty/README.md) | `~/.config/ghostty/` | Ghostty terminal config |
| [`kitty`](kitty/README.md) | `~/.config/kitty/` | Kitty terminal config |
| [`wezterm`](wezterm/README.md) | `~/.config/wezterm/` | WezTerm terminal config |
| [`nvim`](nvim/README.md) | `~/.config/nvim/` | Neovim config |
| [`vim`](vim/README.md) | `~/.vim/vimrc` | Lightweight classic Vim config |
| [`tmux`](tmux/README.md) | `~/.tmux.conf` | tmux config |
| [`starship`](starship/README.md) | `~/.config/starship.toml` | Starship prompt |
| [`qutebrowser`](qutebrowser/README.md) | `~/.config/qutebrowser/` | qutebrowser config |
| [`opencode`](opencode/README.md) | `~/.config/opencode/` | opencode agent config |
| [`pi`](pi/README.md) | `~/.pi/agent/` | Pi coding-agent config |
| [`claude`](claude/README.md) | `~/.claude/` | Claude Code global config |
| [`codex`](codex/README.md) | — | Codex CLI config notes (documentation only, nothing stowed) |
| [`agy`](agy/README.md) | — | Antigravity CLI (agy) config notes (documentation only, nothing stowed) |
| [`openspec`](openspec/README.md) | `~/.config/openspec/` | OpenSpec CLI global config (workflow profile) |
| [`agent-skills`](agent-skills/README.md) | `~/.agents/skills/`, `~/.claude/skills/` | Shared coding-agent skills, including Playwright CLI |
| [`fonts`](fonts/README.md) | `~/.local/share/fonts/` | Nerd Fonts |
| [`scripts`](scripts/README.md) | `~/.local/bin/` | Personal scripts |

> **Terminals:** ghostty is the daily driver; alacritty, kitty, and wezterm are
> kept as configured alternates. All four pin the same font (0xProto Nerd Font
> Mono) and Nightfox-family theme — a font or theme change must be mirrored in
> each config.

Directories prefixed with `_` are **not** stow packages — just stored in the
repo. The `dots` CLI excludes hidden and underscore-prefixed directories from
package discovery:

| Dir | Purpose |
| --- | --- |
| [`_bash`](_bash/README.md) | Modular bash config, *sourced* not stowed |
| [`_dots`](_dots/README.md) | Repo-local dotfiles orchestration tooling |
| [`_helpers`](_helpers/README.md) | Install/update scripts for tools |
| [`_wallpapers`](_wallpapers/README.md) | Wallpaper / terminal background images |

> **Note:** `.gitignore` does **not** affect Stow. Repository-wide ignore
> patterns live in `.stowrc`, which GNU Stow reads when invoked from this repo.
> Run raw Stow from `~/.dots`; the `dots` wrapper does this automatically.

## Setup on a new machine

This repo is written for **Pop!_OS / Debian** (apt, GNU coreutils, Linux
x86_64). Package names differ from other distros — notably `fd-find` provides
the `fdfind` binary and `bat` provides `batcat`; the bash config accounts for
these. Helper scripts in [`_helpers/`](_helpers/README.md) assume Linux x86_64 +
apt/sudo.

```bash
sudo apt install stow            # if not already installed
git clone <repo> ~/.dots
cd ~/.dots

# Install the repo-local orchestration CLI entrypoint:
./setup.sh

# Preview, then symlink the packages you want. dots wraps GNU Stow with
# --dir/--target fixed to this repo and $HOME.
dots stow
dots stow --apply

# _bash is sourced, not stowed — add this to ~/.bashrc:
#   [ -f "$HOME/.dots/_bash/_init_.sh" ] && source "$HOME/.dots/_bash/_init_.sh"
cp _bash/local.sh.example _bash/local.sh   # then edit for this machine
```

Packages that need activation beyond `stow` (starship enablement, `fc-cache`
for fonts, TPM for tmux, first-run order for nvim/pi/opencode) document it in
their own README — follow the links in the tables above.

## Managing packages

After `./setup.sh` links the repo-local `dots` CLI into `~/.local/bin`, use it for the common workflow:

```bash
dots status          # show missing/conflicted/non-symlinked package files
dots doctor          # run repo health checks
dots check           # run portable CI-safe validation
dots stow            # dry-run all packages
dots stow --apply    # stow all packages
dots restow nvim     # dry-run a restow; add --apply to mutate
dots diff starship   # compare live target files with repo sources
```

Raw Stow still works. All commands assume `--dir "$HOME/.dots" --target "$HOME"`
(omitted below for brevity; add them, or run from `~/.dots` where `$HOME` is the
default target).

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

## Adding a package

1. Create `<pkg>/` with the `$HOME`-mirroring layout inside (e.g.
   `<pkg>/.config/<pkg>/...`).
2. Add a `<pkg>/README.md` (see any existing package for the rough shape —
   what it is, deploy path, activate, deps).
3. Add a row to the package table above.
4. `bash _helpers/verify-readmes.sh` to confirm nothing's missing.

## Implement next/later

See [`TODO.md`](TODO.md).
