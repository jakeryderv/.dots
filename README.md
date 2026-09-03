# dotfiles

My personal dotfiles for Pop!_OS / bash. Configuration is deployed as symlinks
from a declarative [`dots.toml`](dots.toml) by [`dots`](_dots/dots.py); the
software that configuration describes is declared in [`flake.nix`](flake.nix)
and installed by Nix.

```bash
dots status          # what is deployed, and does it match dots.toml
dots plan            # preview link changes (never mutates)
dots apply           # create or repoint symlinks
dots check           # the repository gate CI runs
dots doctor          # health checks against this machine
```

## How it works

[`dots.toml`](dots.toml) is the single source of truth for what deploys where.
One table per package, each declaring a mode and a target:

```toml
[packages.nvim]
mode = "link"
target = "~/.config/nvim"

[packages.claude]
mode = "tree"
target = "~/.claude"

[packages.kanata]                 # one package, two places
mode = "link"
links = [
  { source = "kanata.kbd",     target = "~/.config/kanata/kanata.kbd" },
  { source = "kanata.service", target = "~/.config/systemd/user/kanata.service" },
]
```

The source is `config/<name>/` unless the table says otherwise.

**`link`** places one symlink at the target, so new files inside the source
appear automatically. Use it when the directory is exclusively ours.

**`tree`** creates real directories and links each tracked file individually.
Use it when the tool writes state into the same directory it reads config from
(`~/.config/herdr` also holds sockets and `session-history.json`), or when the
target is shared with other installers (most of `~/.local/bin` belongs to other
tools).

Nothing is inferred. The mode is declared, and the package name is the table
key, because both were once derived from paths and both were wrong.

### Files are enumerated with `git ls-files`

This is the load-bearing decision. `.gitignore` is the repo's **only** ignore
list: an untracked file is never deployed, and there is no second ignore syntax
to keep in sync.

The consequence is a rule that applies to every package directory:

> **A package directory contains only deployable content.**

Documentation therefore lives in [`docs/`](docs/README.md) as `docs/<pkg>.md`,
never inside a package. A `README.md` in `config/nvim/` would deploy to
`~/.config/nvim/README.md`, and `dots validate` refuses one.

### Config is linked; software comes from a flake

`dots` only ever moves configuration. The binaries that configuration describes
are declared in [`flake.nix`](flake.nix) and pinned by a committed
`flake.lock` — same idea, other half of the machine:

```bash
nix profile add ~/.dots      # install the toolchain
dots apply                   # link the config
```

Neither one is optional on a fresh machine, and neither infers anything. What
Nix cannot supply stays a script in [`tools/`](tools/README.md), with the reason
recorded. See [`docs/nix.md`](docs/nix.md).

## Layout

| Path | Purpose |
| --- | --- |
| [`dots.toml`](dots.toml) | What deploys where |
| [`config/`](config/README.md) | One directory per package, deployable content only |
| [`docs/`](docs/README.md) | One file per package |
| [`flake.nix`](flake.nix) | The toolchain, pinned by `flake.lock` |
| [`shell/`](shell/README.md) | Modular bash config, *sourced* from `~/.bashrc`, not linked |
| [`_dots/`](_dots/README.md) | The `dots` tool, the repo gate, and tests |
| [`tools/`](tools/README.md) | Installers for what nixpkgs cannot supply (`dots tools`) |
| [`_wallpapers/`](_wallpapers/README.md) | Wallpaper / terminal background images |

Only `config/` is ever deployed, and only the parts `dots.toml` names. The `_`
prefix on the rest is a readability convention, not a mechanism.

## Packages

`dots packages` lists them; each is documented in [`docs/`](docs/README.md).

**Terminals** — [ghostty](docs/ghostty.md) (daily driver),
[alacritty](docs/alacritty.md), [kitty](docs/kitty.md),
[wezterm](docs/wezterm.md). All four pin the same font (0xProto Nerd Font Mono)
and a Nightfox-family theme; a font or theme change must be mirrored in each.

**Editors & shell** — [nvim](docs/nvim.md), [vim](docs/vim.md),
[tmux](docs/tmux.md), [starship](docs/starship.md), [git](docs/git.md),
[bat](docs/bat.md), [direnv](docs/direnv.md),
[editorconfig](docs/editorconfig.md), [tealdeer](docs/tealdeer.md).

**Coding agents** — [claude](docs/claude.md),
[agent-skills](docs/agent-skills.md) (skills shared by every agent),
[herdr](docs/herdr.md) (terminal workspace manager).

**Desktop & misc** — [fonts](docs/fonts.md),
[scripts](docs/scripts.md), [kanata](docs/kanata.md) (keyboard remapping),
[nix](docs/nix.md) (the flakes opt-in; the flake itself is documented there).

## Conventions

- **[`.editorconfig`](.editorconfig) is the indentation source of truth** —
  4-space default, 2 for lua/web/markdown, tabs for Makefiles. Neovim reads it
  natively, and so do the formatters conform runs (`stylua`, `prettierd`,
  `shfmt`), so the editor and the formatters can't drift apart. It is a
  root-level file, not a package, so it is never deployed. The
  [`editorconfig`](docs/editorconfig.md) package deploys the same rules to
  `~/.editorconfig` as a fallback for projects that ship no config of their own.
- **[`.shellcheckrc`](.shellcheckrc) configures ShellCheck once**, for both the
  editor (via bash-language-server) and CI (`_dots/checks/check-repo.sh`), so
  diagnostics match what the gate enforces.
- **Formatting is enforced in CI, per language, with no flags.** `shfmt` for
  bash, `stylua` for Lua, `ruff` for Python; each reads the same config the
  editor's format-on-save reads, so the two cannot disagree. Bulk reformats
  belong in their own commit, listed in
  [`.git-blame-ignore-revs`](.git-blame-ignore-revs).
- **CI runs the flake's binaries.** The workflow pulls every gate tool from the
  nixpkgs revision `flake.lock` pins, via `nix shell --inputs-from .`, so the
  gate cannot drift from the editor.
- **Every package is documented** in `docs/<pkg>.md`, covering what it is, where
  it deploys, how to activate it, and any external dependencies.
  `dots validate` enforces this against `dots.toml`.

## Setup on a new machine

Written for **Pop!_OS / Debian** (apt, GNU coreutils, Linux x86_64). Helper
scripts assume Linux x86_64 + apt/sudo.

Debian renames two of these — `fd-find` provides `fdfind`, `bat` provides
`batcat` — which is why both come from [`flake.nix`](flake.nix) under their
canonical names instead. apt's `bat` was removed along with every other apt
copy of a flake tool; `fd-find` stays because `pop-launcher` depends on it, and
the names do not collide. The guarded alias in `shell/aliases.sh` is the
fallback for a machine without the flake, not the mechanism.

```bash
git clone <repo> ~/.dots
cd ~/.dots

# The toolchain first: python3, which `dots` runs on, comes from the flake.
# The flag is the flakes opt-in; `dots apply` then deploys the same setting
# to ~/.config/nix/nix.conf, so it is typed exactly once.
nix --extra-experimental-features 'nix-command flakes' profile add ~/.dots

python3 _dots/dots.py plan       # preview every link
python3 _dots/dots.py apply      # deploy; from here on, plain `dots`

# shell/ is sourced, not linked — wire it into ~/.bashrc by hand. Use the
# snippet in shell/README.md, which warns instead of failing silently if the
# loader ever goes missing. This is the one step `dots apply` cannot do.
cp shell/local.sh.example shell/local.sh   # then edit for this machine
cp config/git/gitconfig.local.example ~/.gitconfig.local
```

`dots apply` refuses to overwrite an existing real file, reporting it as a
conflict rather than clobbering it. Back it up and remove it, then re-run.

Packages needing activation beyond linking (starship enablement, `fc-cache` for
fonts, TPM for tmux, first-run order for nvim) document it in their
own `docs/<pkg>.md`.

Nix itself is the one bootstrap this repo does not manage, alongside the daemon
settings in `/etc/nix/nix.conf` — [`docs/nix.md`](docs/nix.md) has both, per
distro. `dots deps` reports what is missing.

## Adding a package

1. `mkdir config/<name>/` and put the files in it — **only** deployable content.
2. Add `[packages.<name>]` to [`dots.toml`](dots.toml), choosing `link` or
   `tree` (see the header there).
3. Write `docs/<name>.md`.
4. `dots plan <name>` to preview, then `dots apply <name>`.
5. `dots check` to confirm the gate stays green.

## History

This repo used GNU Stow until August 2026, then a bash deployer driven by a
whitespace-column manifest, then the Python `dots` and `dots.toml` in September.
Most of the design — explicit modes, `git ls-files` enumeration, nothing
inferred — is a reaction to a specific failure of Stow's implicit behaviour,
and survived both rewrites.

## Implement next/later

See [`TODO.md`](TODO.md).
