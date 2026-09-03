# dotfiles

My personal dotfiles for Pop!_OS / bash, deployed from a declarative
[`manifest`](dots.toml) by [`_dots/bin/link.sh`](_dots/dots.py) and driven
through [`just`](https://github.com/casey/just).

```bash
just status          # what is deployed, and does it match the manifest
just plan            # preview link changes (never mutates)
just apply           # create or repoint symlinks
just check           # the repository gate CI runs
```

## How it works

The [`manifest`](dots.toml) is the single source of truth. Each row declares a
package, a link mode, a repo-relative source, and a target:

```
PKG          MODE   SOURCE                TARGET
nvim         link   pkgs/nvim           $XDG_CONFIG_HOME/nvim
scripts      tree   bin                   $HOME/.local/bin
claude       tree   pkgs/claude           $HOME/.claude
```

**`link`** places one symlink at the target, so new files inside the source
appear automatically. Use it when the directory is exclusively ours.

**`tree`** creates real directories and links each tracked file individually.
Use it when the tool writes state into the same directory it reads config from
(`~/.config/herdr` also holds sockets and `session-history.json`), or when the target is shared
with other installers (most of `~/.local/bin` belongs to other tools).

Nothing is inferred. Both the package name and the link shape are declared,
because both were previously inferred and both were wrong.

### Files are enumerated with `git ls-files`

This is the load-bearing decision. `.gitignore` is the repo's **only** ignore
list: an untracked file is never deployed, and there is no second ignore syntax
to keep in sync.

The consequence is a rule that applies to every source directory:

> **A source directory contains only deployable content.**

Documentation therefore lives in [`docs/`](docs/README.md) as `docs/<pkg>.md`,
never inside a source. A `README.md` in `pkgs/nvim/` would deploy to
`~/.config/nvim/README.md`.

### Config is linked; software comes from a flake

The manifest only ever moves configuration. The binaries that configuration
describes are declared in [`flake.nix`](flake.nix) and pinned by a committed
`flake.lock` — same idea, other half of the machine:

```bash
nix profile add ~/.dots      # install the toolchain
just apply                   # link the config
```

Neither one is optional on a fresh machine, and neither infers anything. What
Nix cannot supply stays a script in [`tools/`](tools/README.md), with the reason
recorded. See [`docs/nix.md`](docs/nix.md).

## Layout

| Directory | Deploys to | Contents |
| --- | --- | --- |
| [`config/`](pkgs/README.md) | `$XDG_CONFIG_HOME` (`~/.config`) | Tools that respect XDG |
| [`home/`](pkgs/README.md) | `$HOME` | Tools that don't — stored undotted (`pkgs/git/gitconfig` → `~/.gitconfig`) |
| [`data/`](pkgs/README.md) | `$XDG_DATA_HOME` (`~/.local/share`) | Fonts |
| `bin/` | `~/.local/bin` | Personal scripts (a manifest source, so no README inside — see [`docs/scripts.md`](docs/scripts.md)) |
| [`docs/`](docs/README.md) | — | One file per package |

The size of `home/` measures how much of the toolchain still ignores XDG. It
should shrink, not grow.

The rest is repo infrastructure. None of it is named in the manifest, which is
what makes it undeployable — the `_` prefix is a readability convention, not a
mechanism:

| Dir | Purpose |
| --- | --- |
| [`shell`](shell/README.md) | Modular bash config, *sourced* not linked |
| [`_dots`](_dots/README.md) | The deployer, the repo gate, health checks, and tests |
| [`tools`](tools/README.md) | Install/update scripts for third-party software (`just tools`) |
| [`_wallpapers`](_wallpapers/README.md) | Wallpaper / terminal background images |

## Packages

20 packages across 22 manifest rows. `just packages` lists them; each is
documented in [`docs/`](docs/README.md).

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
  root-level file, not a manifest source, so it is never deployed. The
  [`editorconfig`](docs/editorconfig.md) package deploys the same rules to
  `~/.editorconfig` as a fallback for projects that ship no config of their own.
- **[`.shellcheckrc`](.shellcheckrc) configures ShellCheck once**, for both the
  editor (via bash-language-server) and CI (`_dots/checks/check-repo.sh`), so
  diagnostics match what the gate enforces.
- **Bash formatting is enforced in CI** — `check-repo.sh` runs `shfmt --diff`
  with no flags, so it reads the same `.editorconfig` as format-on-save. If it
  fails, `shfmt -w <file>` fixes it. Bulk reformats belong in their own commit,
  listed in [`.git-blame-ignore-revs`](.git-blame-ignore-revs).
- **CI runs the flake's binaries.** The workflow pulls `shfmt`, `shellcheck`,
  `stylua`, and `kanata` from the nixpkgs revision `flake.lock` pins, via
  `nix shell --inputs-from .`, so the gate cannot drift from the editor.
- **Every package is documented** in `docs/<pkg>.md`, covering what it is, where
  it deploys, how to activate it, and any external dependencies.
  `_dots/checks/verify-readmes.sh` enforces this against the manifest.

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

# The toolchain first — `just` itself comes from the flake, so this is the only
# ordering that works. The flag is the flakes opt-in; `just apply` then deploys
# the same setting to ~/.config/nix/nix.conf, so it is typed exactly once.
nix --extra-experimental-features 'nix-command flakes' profile add ~/.dots

just plan            # preview every link
just apply           # deploy

# shell/ is sourced, not linked — wire it into ~/.bashrc by hand. Use the
# snippet in shell/README.md, which warns instead of failing silently if the
# loader ever goes missing. This is the one step `just apply` cannot do.
cp shell/local.sh.example shell/local.sh   # then edit for this machine
cp pkgs/git/gitconfig.local.example ~/.gitconfig.local
```

`just apply` refuses to overwrite an existing real file, reporting it as a
conflict rather than clobbering it. Back it up and remove it, then re-run.

Packages needing activation beyond linking (starship enablement, `fc-cache` for
fonts, TPM for tmux, first-run order for nvim) document it in their
own `docs/<pkg>.md`.

Nix itself is the one bootstrap this repo does not manage, alongside the daemon
settings in `/etc/nix/nix.conf` — [`docs/nix.md`](docs/nix.md) has both, per
distro. `just deps` reports what is missing.

## Adding a package

1. Create the source directory under `config/`, `home/`, `data/`, or `bin/`,
   containing **only** deployable content.
2. Add a manifest row, choosing `link` or `tree` (see the manifest header).
3. Write `docs/<pkg>.md`.
4. `just plan <pkg>` to preview, then `just apply <pkg>`.
5. `just check` to confirm the gate stays green.

## History

This repo used GNU Stow until August 2026. Most of the design here — the
explicit manifest, `git ls-files` enumeration, nothing inferred — is a reaction
to a specific failure of Stow's implicit behaviour.

## Implement next/later

See [`TODO.md`](TODO.md).
