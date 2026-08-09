# tools

Install/update scripts for tools that aren't deployed from the manifest.

**Never deployed.** This directory is not named in the [`manifest`](../manifest),
which is the only thing that makes anything deployable. Run these scripts
through `just`, or directly.

## Assumptions

Written for **Linux x86_64 + apt/sudo** (Pop!_OS / Debian). Each script's header
documents its exact assumptions and whether it mutates anything outside the
repo. Release installers verify GitHub-provided SHA-256 digests;
`tmux-sessionizer` is pinned to a reviewed commit and checksum. Scripts are safe
to re-run to update unless their header says a pin must be bumped deliberately.

## Scripts

| Script | Installs | Notes |
|--------|----------|-------|
| `check-repo.sh` | — | Portable syntax, parser, lint, format, and behavior checks used by CI. Needs `shellcheck`, `shfmt`, `luac`; each is skipped when missing unless `REQUIRE_LINTERS=1` (which CI sets) makes it fatal. The `shfmt` check runs `--diff` with **no flags**, so it reads `.editorconfig` and enforces exactly what Neovim's format-on-save produces. |
| `install-delta.sh` | [delta](https://github.com/dandavison/delta) | Verified official `.deb` via `dpkg`. Skips the download when already current; `--force` reinstalls. Wire it into [`git`](../docs/git.md) yourself — see the script's closing note. |
| `install-fzf.sh` | [fzf](https://github.com/junegunn/fzf) | Cloned to `~/.fzf`. `--all` **edits your shell rc files** to add keybindings/completion. |
| `install-glow.sh` | [glow](https://github.com/charmbracelet/glow) | Charm apt repo. Markdown renderer used by [`_bash`](../_bash/README.md)'s `llm.sh`. |
| `install-lazygit.sh` | [lazygit](https://github.com/jesseduffield/lazygit) | Verified GitHub release binary → `/usr/local/bin`. |
| `install-playwright-cli.sh` | [Playwright CLI](https://playwright.dev/agent-cli/installation) | Global npm CLI + its Chromium build. Shared Agent Skill is tracked in [`agent-skills`](../docs/agent-skills.md). |
| `install-qutebrowser.sh` | [qutebrowser](https://qutebrowser.org) | From source via `uv` + `mkvenv.py` (newer Qt than apt). `--keep` reuses the venv for a fast update. Also installs the `.desktop` entry + icons. See [`qutebrowser`](../docs/qutebrowser.md). |
| `install-t3code.sh` | [T3 Code](https://t3.codes) | Verified official x86_64 AppImage → `~/.local/opt/t3code`, symlinked to `~/.local/bin`; also installs launcher entry + icon. The app handles routine updates itself. |
| `install-tealdeer.sh` | [tealdeer](https://github.com/tealdeer-rs/tealdeer) | Verified static release binary → `/usr/local/bin/tldr`, plus its bash completion. Skips the download when already current; `--force` reinstalls. Newer than apt's `tealdeer`. Run `tldr --update` once to seed the page cache. |
| `install-tmux-sessionizer.sh` | [tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer) | Pinned commit + checksum → `~/.local/bin`. Used by [`tmux`](../docs/tmux.md). |
| `update-nvim.sh` | [Neovim](https://neovim.io) | Verified official `.tar.gz` stable build → `/opt`, symlinked to `/usr/local/bin`. See [`nvim`](../docs/nvim.md) (needs ≥ 0.12). |
| `verify-agent-skills.sh` | — | Validates the canonical shared-skill tree; `--live` also checks four-agent wiring and duplicate absence. |
| `verify-readmes.sh` | — | Checks every manifest package has `docs/<pkg>.md`, and every top-level directory that is not itself a manifest source has a `README.md`. |

## Usage

```bash
just tools               # list the installers
just install delta       # run tools/install-delta.sh
just update-nvim         # the one non-`install-` installer
just check               # tools/check-repo.sh, what CI runs
just readmes             # tools/verify-readmes.sh
```

Anything without a recipe runs directly:

```bash
bash tools/<script>.sh
```

Read the script's header comment first — some (notably `install-fzf.sh`) mutate
files outside the repo.
