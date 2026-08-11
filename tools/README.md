# tools

Install and update scripts for third-party software that this repo configures
but does not ship.

**Never deployed.** This directory is not named in the [`manifest`](../manifest),
which is the only thing that makes anything deployable.

Everything here provisions software on the machine. The repo's own validation
scripts — `check-repo.sh`, `verify-readmes.sh`, `verify-agent-skills.sh` — live
in [`_dots/checks/`](../_dots/README.md) alongside the deployer they validate,
so this directory has exactly one job.

## Assumptions

Written for **Linux x86_64 + apt/sudo** (Pop!_OS / Debian). Each script's header
documents its exact assumptions and whether it mutates anything outside the
repo. Release installers verify GitHub-provided SHA-256 digests;
`tmux-sessionizer` is pinned to a reviewed commit and checksum. Scripts are safe
to re-run to update unless their header says a pin must be bumped deliberately.

## Shared library

The installers that download GitHub release assets (`delta`, `lazygit`,
`tealdeer`, `t3code`, `nvim`, `kanata`, `ast-grep`, `freecad`) source
[`lib/github-release.sh`](lib/github-release.sh)
for the parts that must not drift between them: platform and dependency
preflight, latest-release resolution, asset selection, and the SHA-256 digest
verification on every download. Each script keeps only what is genuinely its
own — how the installed version is detected, the install step itself, and the
post-install notes. The library is tested offline by
`_dots/tests/github-release-test.sh` against a fixture release and a stubbed
`curl`. The other installers use different mechanisms (apt repos, git clones,
source builds) and stay self-contained.

## Scripts

| Script | Installs | Notes |
|--------|----------|-------|
| `install-ast-grep.sh` | [ast-grep](https://github.com/ast-grep/ast-grep) | Verified release zip → `/usr/local/bin`, plus a bash completion the binary generates. Skips the download when already current; `--force` reinstalls. The zip's deprecated `sg` alias is **not** installed — `/usr/bin/sg` is already the `login` package's. |
| `install-delta.sh` | [delta](https://github.com/dandavison/delta) | Verified official `.deb` via `dpkg`. Skips the download when already current; `--force` reinstalls. Wire it into [`git`](../docs/git.md) yourself — see the script's closing note. |
| `install-freecad.sh` | [FreeCAD](https://github.com/FreeCAD/FreeCAD) | Verified official AppImage (~820 MB) → `~/.local/opt/freecad`, symlinked to `~/.local/bin`; also installs launcher entry + icons. No sudo. Tracks the **stable** release, not the `weekly-*` prereleases; skips the download when already current. Needs `libfuse2t64`. |
| `install-fzf.sh` | [fzf](https://github.com/junegunn/fzf) | Cloned to `~/.fzf`. `--all` **edits your shell rc files** to add keybindings/completion. |
| `install-glow.sh` | [glow](https://github.com/charmbracelet/glow) | Charm apt repo. Markdown renderer used by [`shell`](../shell/README.md)'s `llm.sh`. |
| `install-kanata.sh` | [kanata](https://github.com/jtroo/kanata) | Verified GitHub release binary → `/usr/local/bin`, the build compiled *without* `cmd` support. Binary only: `/dev/input` + `/dev/uinput` access is a deliberate manual step. See [`kanata`](../docs/kanata.md). |
| `install-lazygit.sh` | [lazygit](https://github.com/jesseduffield/lazygit) | Verified GitHub release binary → `/usr/local/bin`. Skips the download when already current; `--force` reinstalls. |
| `install-playwright-cli.sh` | [Playwright CLI](https://playwright.dev/agent-cli/installation) | Global npm CLI + its Chromium build. Shared Agent Skill is tracked in [`agent-skills`](../docs/agent-skills.md). |
| `install-qutebrowser.sh` | [qutebrowser](https://qutebrowser.org) | From source via `uv` + `mkvenv.py` (newer Qt than apt). `--keep` reuses the venv for a fast update. Also installs the `.desktop` entry + icons. See [`qutebrowser`](../docs/qutebrowser.md). |
| `install-t3code.sh` | [T3 Code](https://t3.codes) | Verified official x86_64 AppImage → `~/.local/opt/t3code`, symlinked to `~/.local/bin`; also installs launcher entry + icon. The app handles routine updates itself. |
| `install-tealdeer.sh` | [tealdeer](https://github.com/tealdeer-rs/tealdeer) | Verified static release binary → `/usr/local/bin/tldr`, plus its bash completion. Skips the download when already current; `--force` reinstalls. Newer than apt's `tealdeer`. Run `tldr --update` once to seed the page cache. |
| `install-tmux-sessionizer.sh` | [tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer) | Pinned commit + checksum → `~/.local/bin`. Used by [`tmux`](../docs/tmux.md). |
| `install-nvim.sh` | [Neovim](https://neovim.io) | Verified official `.tar.gz` stable build → `/opt`, symlinked to `/usr/local/bin`. See [`nvim`](../docs/nvim.md) (needs ≥ 0.12). |

## Usage

```bash
just tools               # list the installers
just install delta       # run tools/install-delta.sh
```

Or run any of them directly:

```bash
bash tools/<script>.sh
```

Read the script's header comment first — some (notably `install-fzf.sh`) mutate
files outside the repo.
