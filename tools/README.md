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

## Scripts

| Script | Installs | Notes |
| --- | --- | --- |
| `install-npm-globals.sh` | [Pi](https://pi.dev), [cf](https://www.npmjs.com/package/cf) + [wrangler](https://developers.cloudflare.com/workers/wrangler/), [Playwright CLI](https://playwright.dev/agent-cli/installation) | The npm-only CLIs, in one pass. Installed with `--ignore-scripts`; playwright-cli additionally fetches its Chromium into `~/.cache/ms-playwright`. `cf` is the newer generated CLI covering the whole API, `wrangler` the Workers build toolchain — overlapping but converging, see [`claude`](../docs/claude.md). Auth is **not** installed: each CLI holds its own OAuth grant (`cf auth login`, `wrangler login`). Global prefix is `~/.npm-global`. |
| `install-qutebrowser.sh` | [qutebrowser](https://qutebrowser.org) | From source via `uv` + `mkvenv.py` (newer Qt than apt). `--keep` reuses the venv for a fast update. Also installs the `.desktop` entry + icons. See [`qutebrowser`](../docs/qutebrowser.md). |
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

**GUI on a non-NixOS host** — `qutebrowser`. nixpkgs 3.7.0 matches what
`install-qutebrowser.sh` builds from source, so migrating it would retire the
`uv` + `mkvenv.py` build. What stops it being a one-liner is graphics.

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

Reaching the **NVIDIA dGPU** does not work. `nix-gl-host` (which borrows the
host driver, so no version pinning) does get EGL onto the 5070 Ti -- `eglinfo`
confirms it -- but it prepends host library directories to `LD_LIBRARY_PATH`,
which shadows nixpkgs' own libraries. Plain C programs tolerate that; Qt6 does
not, and a Qt app dies with `QRhiGles2: Failed to create context` on both the
xcb and wayland platforms. GLX stays broken under it too. (Measured with
FreeCAD, whose installer has since been removed.)

The iGPU is fine for a browser, so qutebrowser remains a genuine candidate --
it just needs a wrapper setting those three variables, and has not been
trialled.

## Usage

```bash
just tools               # list the installers
just install npm-globals # run tools/install-npm-globals.sh
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
