# tools

There are currently no maintained installer scripts. Tool/package sources,
installation methods, official documentation and machine-specific conventions
live in [docs/software.md](../docs/software.md).

The former npm globals installer was retired during the Node/nvm migration.
Use the standard npm commands recorded in the inventory. `dots tools` lists
any installer scripts present; it is currently empty.

This directory is not deployed by `dots apply`. The notes below retain the
reasons some applications were kept outside the Nix bundle.

## Historical packaging decisions

Measured 2026-09-02, on Pop!_OS 24.04 / COSMIC Wayland, hybrid Intel Arrow Lake
+ NVIDIA (proprietary 580.173.02). Recorded so the question is not re-opened
from scratch.

**Absent from nixpkgs** — `pi`, `playwright-cli`, and `cf`. Nothing to migrate.
(nixpkgs has `playwright-driver`, but not the agent CLI.)

**Present in nixpkgs, but wraps a Nix browser** — `mermaid-cli` renders through
puppeteer. The nixpkgs package bundles nixpkgs' chromium, which puts it in the
GUI-under-Nix category below; the npm install downloads its own Chrome
instead. Headless was not tested, so this is the weakest rejection here and the
one to revisit if a Nix browser is ever shown to work on this host.

**Different upstream** — `tmux-sessionizer` was here until its script was
vendored into [`config/scripts/`](../docs/scripts.md). nixpkgs packages jrmoulton's Rust
rewrite, whose binary is `tms` and whose config format differs; this repo uses
ThePrimeagen's shell script, which `config/tmux/tmux.conf` and `config/bash/bashrc` call
by name. Same name, different project.

**Self-updating** — `herdr` is installed by its own installer to
`~/.local/bin/herdr` and keeps itself current with `herdr update` on a `stable`
or `preview` channel. nixpkgs does have it, at the same 0.8.2 running here, so
availability is not the obstacle: a read-only store has nowhere for `herdr
update` to write, and pinning a 0.8.x tool under active integration would mean
its releases arrive only when `nix flake update` bumps everything else at once.
Writing a custom derivation would not help either, since the nixpkgs package
already exists — the updater is the whole objection. Revisit at 1.0, or when
reproducibility matters more than same-day releases. This is the reason t3code
was rejected in 57fc210; the category outlived that installer.

uv, rustup, Bun and Go have moved out of the flake. Follow their official
installation and update docs linked in the [software inventory](../docs/software.md).
Their existing toolchains and user data stay in place.

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
