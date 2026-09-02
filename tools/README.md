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
repo. Scripts are safe to re-run to update.

## Scripts

| Script | Installs | Notes |
| --- | --- | --- |
| `install-npm-globals.sh` | [Pi](https://pi.dev), [cf](https://www.npmjs.com/package/cf) + [wrangler](https://developers.cloudflare.com/workers/wrangler/), [Playwright CLI](https://playwright.dev/agent-cli/installation) | The npm-only CLIs, in one pass. Installed with `--ignore-scripts`; playwright-cli additionally fetches its Chromium into `~/.cache/ms-playwright`. `cf` is the newer generated CLI covering the whole API, `wrangler` the Workers build toolchain — overlapping but converging, see [`claude`](../docs/claude.md). Auth is **not** installed: each CLI holds its own OAuth grant (`cf auth login`, `wrangler login`). Global prefix is `~/.npm-global`. |

## Why these stay scripts

Measured 2026-09-02, on Pop!_OS 24.04 / COSMIC Wayland, hybrid Intel Arrow Lake
+ NVIDIA (proprietary 580.173.02). Recorded so the question is not re-opened
from scratch.

**Absent from nixpkgs** — `pi`, `playwright-cli`, and `cf`. Nothing to migrate.
(nixpkgs has `playwright-driver`, but not the agent CLI.)

**Different upstream** — `tmux-sessionizer` was here until its script was
vendored into [`bin/`](../docs/scripts.md). nixpkgs packages jrmoulton's Rust
rewrite, whose binary is `tms` and whose config format differs; this repo uses
ThePrimeagen's shell script, which `home/tmux.conf` and `shell/keybinds.sh` call
by name. Same name, different project.

**GUI apps** — none are left here, but the finding is worth keeping so it is
not re-derived. Three were tested under Nix on this host (qutebrowser, freecad,
t3code) and each was worse than its non-Nix install.

A nixpkgs GUI binary uses Nix's own dynamic linker, which does not search
`/usr/lib`. libglvnd then falls back to the system
`/usr/share/glvnd/egl_vendor.d/`, whose JSONs name libraries in `/usr/lib` that
a Nix process cannot open, so EGL fails to initialize and Qt apps abort
outright. Three variables pointing at Nix's own mesa fix that and give hardware
acceleration on the Intel iGPU:

    __EGL_VENDOR_LIBRARY_DIRS=$MESA/share/glvnd/egl_vendor.d
    LIBGL_DRIVERS_PATH=$MESA/lib/dri
    GBM_BACKENDS_PATH=$MESA/lib/gbm

Two things stay broken even then. The NVIDIA dGPU is unreachable: `nix-gl-host`
borrows the host driver and does get EGL onto it, but it prepends host library
directories to `LD_LIBRARY_PATH`, shadowing nixpkgs' own libraries -- plain C
programs tolerate that, Qt6 does not. And VA-API video decode fails the same
`/usr/lib` way, costing hardware video acceleration.

So a Nix desktop app here needs a wrapper, crashes without it, and still loses
capability the system install has.

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
