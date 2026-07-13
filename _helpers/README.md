# _helpers

Install/update scripts for tools that aren't managed by stow.

**Not a stow package.** The `_` prefix keeps this directory out of `dots`
package discovery. Run these scripts directly.

## Assumptions

Written for **Linux x86_64 + apt/sudo** (Pop!_OS / Debian). Each script's header
documents its exact assumptions and whether it mutates anything outside the
repo. Release installers verify GitHub-provided SHA-256 digests;
`tmux-sessionizer` is pinned to a reviewed commit and checksum. Scripts are safe
to re-run to update unless their header says a pin must be bumped deliberately.

## Scripts

| Script | Installs | Notes |
|--------|----------|-------|
| `check-repo.sh` | — | Portable syntax, parser, lint, and behavior checks used by CI. |
| `install-fzf.sh` | [fzf](https://github.com/junegunn/fzf) | Cloned to `~/.fzf`. `--all` **edits your shell rc files** to add keybindings/completion. |
| `install-glow.sh` | [glow](https://github.com/charmbracelet/glow) | Charm apt repo. Markdown renderer used by [`_bash`](../_bash/README.md)'s `llm.sh`. |
| `install-lazygit.sh` | [lazygit](https://github.com/jesseduffield/lazygit) | Verified GitHub release binary → `/usr/local/bin`. |
| `install-qutebrowser.sh` | [qutebrowser](https://qutebrowser.org) | From source via `uv` + `mkvenv.py` (newer Qt than apt). `--keep` reuses the venv for a fast update. Also installs the `.desktop` entry + icons. See [`qutebrowser`](../qutebrowser/README.md). |
| `install-t3code.sh` | [T3 Code](https://t3.codes) | Verified official x86_64 AppImage → `~/.local/opt/t3code`, symlinked to `~/.local/bin`; also installs launcher entry + icon. The app handles routine updates itself. |
| `install-tmux-sessionizer.sh` | [tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer) | Pinned commit + checksum → `~/.local/bin`. Used by [`tmux`](../tmux/README.md). |
| `update-nvim.sh` | [Neovim](https://neovim.io) | Verified official `.tar.gz` stable build → `/opt`, symlinked to `/usr/local/bin`. See [`nvim`](../nvim/README.md) (needs ≥ 0.12). |

## Usage

```bash
bash _helpers/<script>.sh
```

Read the script's header comment first — some (notably `install-fzf.sh`) mutate
files outside the repo.
