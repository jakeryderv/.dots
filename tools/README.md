# tools

Install and update scripts for third-party software that this repo configures
but does not ship, **for the cases Nix does not cover**.

Most tooling now comes from [`flake.nix`](../flake.nix) in the repo root, which
declares it in one place and pins it with a committed `flake.lock`. What is left
here is what nixpkgs cannot supply, plus the GUI apps where a Nix build would
be a downgrade. See [Why these stay scripts](#why-these-stay-scripts).

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

## Why these stay scripts

Measured 2026-09-02, on Pop!_OS 24.04 / COSMIC Wayland, hybrid Intel Arrow Lake
+ NVIDIA (proprietary 580.173.02). Recorded so the question is not re-opened
from scratch.

**Absent from nixpkgs** — `pi`, `playwright-cli`, and `cf`. Nothing to migrate.
(nixpkgs has `playwright-driver`, but not the agent CLI.)

**Different upstream** — `tmux-sessionizer`. nixpkgs packages jrmoulton's Rust
rewrite, whose binary is `tms`. This repo uses ThePrimeagen's shell script, and
`home/tmux.conf` plus `shell/keybinds.sh` call it by name. Same name, different
project; not a drop-in.

**Self-updating** — `t3code` updates itself in place. The Nix store is
read-only, so packaging it would trade a working updater for manual version
bumps in `flake.nix`.

**GPU-bound** — `freecad`. This one is not about packaging at all:

A nixpkgs GUI binary uses Nix's own dynamic linker, which does not search
`/usr/lib`. With default environment, libglvnd falls back to the system
`/usr/share/glvnd/egl_vendor.d/`, whose JSONs name `libEGL_nvidia.so.0` and
`libEGL_mesa.so.0` in `/usr/lib` -- unopenable from a Nix process. EGL then
fails to initialize at all, software fallback included.

Pointing three variables at Nix's own mesa fixes it, and yields hardware
acceleration on the **Intel iGPU**:

    __EGL_VENDOR_LIBRARY_DIRS=$MESA/share/glvnd/egl_vendor.d
    LIBGL_DRIVERS_PATH=$MESA/lib/dri
    GBM_BACKENDS_PATH=$MESA/lib/gbm

Reaching the **NVIDIA dGPU** is the part that does not work. `nix-gl-host`
(which borrows the host driver, so no version pinning) does get EGL onto the
5070 Ti -- `eglinfo` confirms it -- but it prepends host library directories to
`LD_LIBRARY_PATH`, which shadows nixpkgs' own libraries. Plain C programs
tolerate that; Qt6 does not, and FreeCAD dies with `QRhiGles2: Failed to create
context` on both the xcb and wayland platforms. GLX stays broken under it too.

So a Nix FreeCAD is limited to the Intel iGPU, while the AppImage links against
system libraries and can use the dGPU. For CAD that is a capability
**downgrade**, which is the whole reason to keep the AppImage.

**Still open** — `qutebrowser`. nixpkgs 3.7.0 matches what
`install-qutebrowser.sh` builds from source, and a browser on the iGPU is fine,
so this one would be a real win: it would retire the `uv` + `mkvenv.py` source
build. It needs a wrapper setting the three variables above, and has not been
trialled.

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
nix profile add ~/.dots            # first install
nix flake update --flake ~/.dots   # bump flake.lock, then:
nix profile upgrade 'git+file:///home/jake/.dots#packages.x86_64-linux.default'
```
