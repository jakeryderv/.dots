# nix

[`flake.nix`](../flake.nix) + [`flake.lock`](../flake.lock) — the **software**
half of this repo.

[`dots.toml`](../dots.toml) declares where config goes. The flake declares
what binaries exist. Both are pinned in git, both are applied by one command,
and neither infers anything:

| | Config | Software |
| --- | --- | --- |
| Declared in | [`dots.toml`](../dots.toml) | [`flake.nix`](../flake.nix) |
| Pinned by | git | [`flake.lock`](../flake.lock) |
| Applied by | `dots apply` | `nix profile add ~/.dots` |
| Lands in | `~/.config`, `~`, `~/.local` | `~/.nix-profile/bin` |

The flake builds the same list for `x86_64-linux` and `aarch64-linux`. Only
x86_64 has ever been installed; the second exists so an ARM machine fails on a
missing binary cache entry at worst, not on a missing attribute at
`nix profile add`.

This replaced eight per-tool installers in [`tools/`](../tools/README.md), which
fetched releases at HEAD and so could not reproduce a version on a second
machine. Committing `flake.lock` is what makes them reproducible, the same way
committing `dots.toml` makes the symlinks reproducible.

**Never deployed.** `flake.nix` is a root-level file, not a package, so
`dots apply` does not touch it. `nix profile` owns the install.

## Prerequisites

Nix itself is **not** managed by this repo — it is the one bootstrap step.
This host runs the multi-user daemon install (`nix-daemon.service`,
`/nix/var/nix/profiles/default`).

Nix reads two config files in layers: `/etc/nix/nix.conf`, then
`~/.config/nix/nix.conf` on top of it. They have different owners, and that
split decides what this repo can manage.

**`~/.config/nix/nix.conf` is a package** — the `nix` table in `dots.toml` deploys
[`config/nix/nix.conf`](../config/nix/nix.conf), which holds the flakes opt-in:

```
experimental-features = nix-command flakes
```

Flakes are still experimental, and without that line every command below
fails. It is a *client* setting, so the user file is enough, and the user file
is identical on Debian, Arch and NixOS — which is what makes it a dotfile. Nix
writes `registry.json` beside it, hence the `tree` row.

**`/etc/nix/nix.conf` is bootstrap, not config.** Whatever installed Nix owns
it: the installer's plain file on apt and Arch, a generated read-only file on
NixOS. *Daemon* settings only take effect from there — the daemon runs as root
and never reads `$HOME` — so they are recorded here as a per-machine step
beside installing Nix, not deployed:

| Setting | apt / Arch (official installer) | NixOS (`configuration.nix`) |
| --- | --- | --- |
| `auto-optimise-store = true` | `echo 'auto-optimise-store = true' \| sudo tee -a /etc/nix/nix.conf && sudo systemctl restart nix-daemon` | `nix.settings.auto-optimise-store = true;` |

Then `nix store optimise` once, to hardlink what the store already holds.

**Bootstrap order.** `dots` runs on the flake's python3, and `dots apply` is
what deploys the conf, so the very first command carries the opt-in inline:

```bash
nix --extra-experimental-features 'nix-command flakes' profile add ~/.dots
python3 dots.py apply            # from here on, plain `dots`
```

Every command after that is plain.

## Usage

```bash
nix profile add ~/.dots            # first install (see Bootstrap order above)
nix flake update --flake ~/.dots   # bump flake.lock (commit the result)
nix profile upgrade --all          # rebuild the profile from the new lock
```

`--all` is deliberate. The entry is not named `dots-tools` — that is the
`buildEnv` name inside the derivation — and `nix profile` names it by its flake
URL, which `nix profile list` prints in full. Upgrading by the wrong name warns
that nothing matched rather than failing, a silent no-op; `--all` sidesteps the
question because this profile holds exactly one entry. Run it from a clean tree:
a dirty checkout evaluates, but locks the entry without a revision.

Everything installs as a single `buildEnv` package, so it upgrades or rolls back
as one unit. `nix profile rollback` undoes a bad update wholesale.

## What is in it

Read [`flake.nix`](../flake.nix) for the list — every non-obvious entry carries
the reason it is pinned that way, inline. Broadly:

- **CLI tools** — `ast-grep`, `bat`, `delta`, `fd`, `fzf`, `glow`, `lazygit`,
  `ripgrep`, `tealdeer`
- **Editor** — `neovim`, plus the formatters and linters it shells out to
  (`stylua`, `shfmt`, `shellcheck`, `prettierd`, `eslint_d`)
- **Shell environment** — `git`, `gh`, `tmux`, `starship`, `direnv`
  (with `nix-direnv`, so host and plugin share one owner)
- **Node** — `nodejs`, `pnpm_10`, `yarn`, replacing nvm
- **Toolchain managers** — `uv`, `rustup`, `go`, `bun`; what each of them
  manages stays outside the store, see [below](#machine-versions-vs-project-versions)
- **Python** — `ruff`, beside uv
- **Other** — `kanata` (the systemd unit execs `~/.nix-profile/bin/kanata`),
  `qmk`, `nix-direnv`, and `python3`, which `dots` itself runs on

## Machine versions vs project versions

The rule that decides whether something belongs here at all:

> **The global flake holds tools whose version is a property of the machine.
> Per-project flakes hold toolchains whose version is a property of the
> project.**

A linter, a pager, a multiplexer, a task runner — one version is correct
everywhere, and being on two versions is a bug. Those go here.

A language toolchain is the opposite. `rust-toolchain.toml`, the `go` directive
in `go.mod`, and `.python-version` all exist because the correct version is a
fact about the repository you are standing in, and the global profile can only
hold one. Those go in the project, via [`use flake`](#per-project-toolchains).

`nodejs` is here despite being a language toolchain, and it is worth being
honest about why: in practice there was exactly one version. When
`pi-cli-tools` needed 22 against a global 24, it got a project flake — which is
the rule working, not an exception to it.

The corollary is that **the managers belong here and what they manage does
not.** `uv`, `rustup`, `go` and `bun` are all flake entries; the Pythons in
`~/.local/share/uv`, the toolchains in `~/.rustup`, the versions
`GOTOOLCHAIN=auto` fetches into the module cache, and bun's `~/.bun` cache are
not. Pinning uv says nothing about which Python a project uses, and pinning
rustup says nothing about which Rust. Go and bun are the node case again: one
base version that is right machine-wide, with the per-project layer handled by
the tool itself or by a project flake. Replacing a manager with a pinned global
toolchain would trade a correct per-project answer for one machine-wide guess;
pinning the manager costs nothing.

The store is read-only, so `rustup self update` and `uv self update` are
disabled in the nixpkgs builds and `bun upgrade` fails; updating any of them
means updating the flake. `~/.cargo/bin` stays on `PATH` for `cargo install`
output and `~/go/bin` for `go install` output -- both *after* the profile, so
neither can shadow it.

## Two managers, one rule

Machine-level CLIs come from two places, and that is deliberate:

| Manager | Holds | Because |
| --- | --- | --- |
| `flake.nix` | everything else | nixpkgs has them |
| [`tools/install-npm-globals.sh`](../tools/README.md) | `pi`, `cf`, `wrangler`, `playwright-cli`, `mermaid-cli` | npm-only, or needs its own browser |

Two managers is not two sources of truth, because the split is by **where the
tool comes from**, not by preference. The rule is narrower than "one manager":

> **One manager per tool, chosen by the tool's origin — and no tool obtainable
> from two.**

The second half is the part that gets violated. Two live examples, both found
by listing every `uv tool` entry against nixpkgs:

- **`ruff`** was a `uv tool` install while the other five formatters and
  linters came from this flake — `docs/nvim.md` said so in its own table. Same
  category, two owners. It moved here.
- **`pyright`** was installed *twice*, by Mason and by `uv tool`. Outside nvim
  the uv copy won; inside nvim, Mason prepends its own bin and won instead — so
  the version depended on where you invoked it. Mason owns language servers, so
  the uv copy was removed. `pyright` is consequently not on the shell `PATH` any
  more; that is what Mason ownership means, and `uvx pyright` covers the
  occasional CLI use.

This is the same failure `2956a44` fixed between apt and Mason. It recurs
whenever a new manager is added, so the check is worth repeating: list what each
manager owns, and look for a tool that appears twice or a category that splits.

Running it in full is what removed the third manager. `uv tool` held eight
entries; auditing each one for actual use retired seven of them, and `qmk` --
the only survivor -- was in nixpkgs, so it moved here. `uv tool list` is now
empty. uv keeps the project layer it is good at, and this table lost a row.

The narrower version of it — a flake binary that another `PATH` entry provides
first — is automated. `dots doctor` reports it, because that one is invisible
otherwise: the package installs, `nix profile list` and `dots deps` both look
healthy, and the shell keeps running the other copy.

## Packaging something nixpkgs does not have

A flake is not limited to what nixpkgs ships, but "package it ourselves" covers
two jobs with very different costs.

**Consuming a pinned artifact.** For a prebuilt release binary this is a
`fetchurl` with a URL and a hash, unpacked and installed — about fifteen lines,
plus `autoPatchelfHook` if it is dynamically linked. Updating means bumping a
version and a hash. This is the declarative form of what
`tools/lib/github-release.sh` used to do imperatively before a46a42e removed it
with its last two consumers.

**Becoming the packager.** `buildGoModule`, `rustPlatform`, `buildNpmPackage` —
now a vendored-dependency hash, the build itself, and every upstream breakage
are this repo's problem, per package, forever.

Everything in the list above consumes *nixpkgs'* work. A custom derivation
trades that for maintenance, so it needs to earn it:

> Write one when the tool is (a) a single prebuilt or trivially built binary,
> (b) not self-updating, and (c) something that would otherwise be
> hand-installed and forgotten. Fail any one and leave it to its own channel.

Audited 2026-09-02 against everything hand-installed on this machine, and
nothing passes yet. The near miss is `runpodctl`: a single static binary with no
self-updater, where nixpkgs is stalled at 2.9.0 against 2.11.0 installed — and
stalled is the word, since current `nixpkgs-unstable` is also 2.9.0, so
`nix flake update` would not close it the way it does for `gh`. That combination
is exactly what (a)-(c) describe, and it is the one to revisit.

Everything else fails (b), and not by coincidence: `claude`, `codex`, `agy`,
`cursor-agent`, `copilot`, and `herdr` all ship their own updater because agent
CLIs release weekly. That is a category, not a list.

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

The payoff is more than tidiness: `dots check` runs `shfmt` and
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
from [`tools/install-npm-globals.sh`](../tools/README.md), as does
`mermaid-cli`, which nixpkgs has but only with a Nix-built browser.
`tmux-sessionizer` is vendored into [`bin/`](scripts.md), because nixpkgs
packages a different project under the same name. Each rejection is recorded
with its reason in [`tools/README.md`](../tools/README.md#why-these-stay-scripts)
so the question is not re-opened from scratch.
