# nix

[`flake.nix`](../flake.nix) + [`flake.lock`](../flake.lock) — the **software**
half of this repo.

The [`manifest`](../manifest) declares where config goes. The flake declares
what binaries exist. Both are pinned in git, both are applied by one command,
and neither infers anything:

| | Config | Software |
| --- | --- | --- |
| Declared in | [`manifest`](../manifest) | [`flake.nix`](../flake.nix) |
| Pinned by | git | [`flake.lock`](../flake.lock) |
| Applied by | `just apply` | `nix profile add ~/.dots` |
| Lands in | `~/.config`, `~`, `~/.local` | `~/.nix-profile/bin` |

This replaced eight per-tool installers in [`tools/`](../tools/README.md), which
fetched releases at HEAD and so could not reproduce a version on a second
machine. Committing `flake.lock` is what makes them reproducible, the same way
committing the manifest makes the symlinks reproducible.

**Never deployed.** `flake.nix` is a root-level file, not a manifest source, so
`just apply` does not touch it. `nix profile` owns the install.

## Prerequisites

Nix itself is **not** managed by this repo — it is the one bootstrap step, like
`just`. This host runs the multi-user daemon install (`nix-daemon.service`,
`/nix/var/nix/profiles/default`).

Flakes are still experimental, and the opt-in lives in an **untracked**
`~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

Without that line every command below fails. It is not in the manifest because
`~/.config/nix` is Nix's own tree and the setting is per-machine.

## Usage

```bash
nix profile add ~/.dots            # first install
nix flake update --flake ~/.dots   # bump flake.lock (commit the result)
nix profile upgrade 'git+file:///home/jake/.dots#packages.x86_64-linux.default'
nix profile list                   # the entry's exact name
```

The upgrade target is the **flake URL**, not `dots-tools`. `dots-tools` is the
`buildEnv` name inside the derivation; `nix profile` names entries by the flake
they came from, and upgrading by the wrong name warns that nothing matched
rather than failing — a silent no-op. `nix profile list` prints the real one.

Everything installs as a single `buildEnv` package, so it upgrades or rolls back
as one unit. `nix profile rollback` undoes a bad update wholesale.

## What is in it

Read [`flake.nix`](../flake.nix) for the list — every non-obvious entry carries
the reason it is pinned that way, inline. Broadly:

- **CLI tools** — `ast-grep`, `delta`, `fd`, `fzf`, `glow`, `lazygit`,
  `ripgrep`, `tealdeer`
- **Editor** — `neovim`, plus the formatters and linters it shells out to
  (`stylua`, `shfmt`, `shellcheck`, `prettierd`, `eslint_d`)
- **Node** — `nodejs`, `pnpm_10`, `yarn`, replacing nvm
- **Other** — `kanata` (the systemd unit execs `~/.nix-profile/bin/kanata`),
  `nix-direnv`

## The rules this boundary follows

Four things were learned the expensive way. They are why the package list looks
the way it does.

### One category, one manager

A category of tool comes from exactly one source, or the two copies shadow each
other on `PATH` and the one you get depends on shell startup order.

- `shfmt` and `shellcheck` were installed by **both** apt and Mason, `stylua`
  and `prettierd` by Mason only, `ripgrep` by apt only — four sources for one
  category. All five moved to the flake, and Mason's copies were uninstalled,
  because Mason prepends its own bin directory inside nvim and would keep
  winning. Language servers stay with Mason: they churn too fast to pin.
- `wrangler` was moved into the flake and then moved back **out**.
  [`tools/install-npm-globals.sh`](../tools/README.md) installs it paired with
  `cf`, which nixpkgs does not have; taking half the pair put two wranglers on
  `PATH` with the npm one shadowing the Nix one.

The payoff is more than tidiness: `_dots/checks/check-repo.sh` runs `shfmt` and
`shellcheck`, so the editor and the repo gate now run the *same pinned
binaries*.

### The store is read-only

Anything that wants to write into its own install directory does not fit.

- `npm install -g` cannot write to the store, so `~/.npmrc` sets
  `prefix=~/.npm-global` and [`shell/exports.sh`](../shell/exports.sh) puts its
  `bin/` on `PATH`.
- Self-updating apps are disqualified outright — see
  [`tools/README.md`](../tools/README.md).

### A Nix binary's linker never searches `/usr/lib`

This is the mechanism behind every Nix breakage seen here so far.

- `image.nvim`'s `magick` luarock called `ffi.load("MagickWand")` and could not
  see the apt-installed ImageMagick. It was fixable — an `LD_LIBRARY_PATH`
  wrapper plus a compat derivation supplying the unversioned `.so` names — but
  the plugin was dropped instead, and the whole chain with it.
- GUI apps fail harder: libglvnd falls back to the system EGL vendor JSONs,
  which name libraries a Nix process cannot open, so Qt aborts at startup. The
  measured details, including why the NVIDIA dGPU stays unreachable, are in
  [`tools/README.md`](../tools/README.md). Three GUI apps were tested and all
  three were worse under Nix.

### Debian renames things

apt ships `fd` as `fdfind` and `bat` as `batcat` to avoid package clashes, and
tools that auto-detect them (telescope, fzf) find neither. nixpkgs provides the
canonical names, which is the whole reason `fd` is in the flake.
`/usr/bin/fdfind` is left alone — the names do not collide.

## Per-project toolchains

The flake is the *global* toolchain. A project needing a different version uses
`nix-direnv`, which the flake also installs and
[`config/direnv/direnvrc`](../config/direnv/direnvrc) sources:

```bash
echo 'use flake' > .envrc && direnv allow
```

This is what replaced nvm's per-project switching. `nix-direnv` caches the
evaluation, so entering a directory is not a full re-eval, and registers the
resulting store paths as GC roots so `nix store gc` cannot collect a dev shell
still in use. See [`direnv.md`](direnv.md).

## What deliberately stays outside

`pi`, `cf`, `wrangler`, and `playwright-cli` are absent from nixpkgs and come
from [`tools/install-npm-globals.sh`](../tools/README.md).
`tmux-sessionizer` is vendored into [`bin/`](scripts.md), because nixpkgs
packages a different project under the same name. Each rejection is recorded
with its reason in [`tools/README.md`](../tools/README.md#why-these-stay-scripts)
so the question is not re-opened from scratch.
