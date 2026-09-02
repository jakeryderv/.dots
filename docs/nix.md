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

- **CLI tools** — `ast-grep`, `bat`, `delta`, `fd`, `fzf`, `glow`, `lazygit`,
  `ripgrep`, `tealdeer`
- **Editor** — `neovim`, plus the formatters and linters it shells out to
  (`stylua`, `shfmt`, `shellcheck`, `prettierd`, `eslint_d`)
- **Shell environment** — `git`, `gh`, `tmux`, `just`
- **Node** — `nodejs`, `pnpm_10`, `yarn`, replacing nvm
- **Python** — `uv` and `ruff`; see [below](#three-managers-one-rule) for what
  uv keeps
- **Other** — `kanata` (the systemd unit execs `~/.nix-profile/bin/kanata`),
  `nix-direnv`

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

The corollary is that **`rustup`, `uv`, and Go's own `GOTOOLCHAIN` are not
competitors to this flake.** They manage the per-project layer, which this
flake does not reach. Replacing them with a pinned global version would trade a
correct per-project answer for one machine-wide guess.

Note the distinction that makes `uv` itself a flake entry: *the tool* is
machine-level, *what it manages* is project-level. Pinning uv says nothing
about which Python any project uses.

## Three managers, one rule

Machine-level CLIs come from three places, and that is deliberate:

| Manager | Holds | Because |
| --- | --- | --- |
| `flake.nix` | most things | nixpkgs has them |
| [`tools/install-npm-globals.sh`](../tools/README.md) | `pi`, `cf`, `wrangler`, `playwright-cli` | npm-only |
| `uv tool` | `llm`, `qtile`, `serena-agent`, `pylatexenc`, `jcodemunch-mcp`, `poetry`, `qmk`, `git-filter-repo` | PyPI-only, or better tracked there |

Three managers is not three sources of truth, because the split is by **where
the tool comes from**, not by preference. The rule is narrower than "one
manager":

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
