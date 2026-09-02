# tools

Install and update scripts for third-party software that this repo configures
but does not ship, **for the cases Nix does not cover**.

Most tooling now comes from [`flake.nix`](../flake.nix) in the repo root, which
declares it in one place and pins it with a committed `flake.lock`. What is left
here is what nixpkgs cannot supply: packages it does not carry (`pi`,
`playwright-cli`, `cf`), a differently-named upstream (`tmux-sessionizer`), and
GUI apps whose Nix builds risk the OpenGL/mesa mismatch on a non-NixOS host
(`freecad`, `t3code`, `qutebrowser`).

**Never deployed.** This directory is not named in the [`manifest`](../manifest),
which is the only thing that makes anything deployable.

Everything here provisions software on the machine. The repo's own validation
scripts — `check-repo.sh`, `verify-readmes.sh` — live
in [`_dots/checks/`](../_dots/README.md) alongside the deployer they validate,
so this directory has exactly one job.

## Assumptions

Written for **Linux x86_64 + apt/sudo** (Pop!_OS / Debian). Each script's header
documents its exact assumptions and whether it mutates anything outside the
repo. Release installers verify GitHub-provided SHA-256 digests;
`tmux-sessionizer` is pinned to a reviewed commit and checksum. Scripts are safe
to re-run to update unless their header says a pin must be bumped deliberately.

## Shared library

The installers that download GitHub release assets (`t3code`, `freecad`)
source
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
| --- | --- | --- |
| `install-cloudflare.sh` | [cf](https://www.npmjs.com/package/cf) + [wrangler](https://developers.cloudflare.com/workers/wrangler/) | Both Cloudflare CLIs as global npm packages, lifecycle scripts disabled. `cf` is the newer generated CLI covering the whole API; `wrangler` is the Workers build toolchain. Overlapping but converging — see [`claude`](../docs/claude.md). Auth is **not** installed: each CLI holds its own OAuth grant (`cf auth login`, `wrangler login`). |
| `install-freecad.sh` | [FreeCAD](https://github.com/FreeCAD/FreeCAD) | Verified official AppImage (~820 MB) → `~/.local/opt/freecad`, symlinked to `~/.local/bin`; also installs launcher entry + icons. No sudo. Tracks the **stable** release, not the `weekly-*` prereleases; skips the download when already current. Needs `libfuse2t64`. |
| `install-pi.sh` | [Pi coding agent](https://pi.dev) | Latest global npm release, installed with lifecycle scripts disabled. Pi config lives in the separate [pi-config](https://github.com/jakeryderv/pi-config) repo (`~/dev/projects/pi-config`). |
| `install-playwright-cli.sh` | [Playwright CLI](https://playwright.dev/agent-cli/installation) | Global npm CLI + its Chromium build. The Agent Skill itself is untracked, managed by skills.sh. |
| `install-qutebrowser.sh` | [qutebrowser](https://qutebrowser.org) | From source via `uv` + `mkvenv.py` (newer Qt than apt). `--keep` reuses the venv for a fast update. Also installs the `.desktop` entry + icons. See [`qutebrowser`](../docs/qutebrowser.md). |
| `install-t3code.sh` | [T3 Code](https://t3.codes) | Verified official x86_64 AppImage → `~/.local/opt/t3code`, symlinked to `~/.local/bin`; also installs launcher entry + icon. The app handles routine updates itself. |
| `install-tmux-sessionizer.sh` | [tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer) | Pinned commit + checksum → `~/.local/bin`. Used by [`tmux`](../docs/tmux.md). |

## Usage

```bash
just tools               # list the installers
just install t3code      # run tools/install-t3code.sh
```

Or run any of them directly:

```bash
bash tools/<script>.sh
```

Read the script's header comment first — some mutate files outside the repo.

## Nix-managed tooling

Everything in [`flake.nix`](../flake.nix) is installed with one command, and
upgraded without touching this directory:

```bash
nix profile add ~/.dots                              # first install
nix flake update --flake ~/.dots \
  && nix profile upgrade dots-tools                  # update everything
```
