# dotfiles

My personal dotfiles for Pop!_OS / bash, deployed from a declarative
[`manifest`](manifest) by [`_dots/bin/link.sh`](_dots/bin/link.sh) and driven
through [`just`](https://github.com/casey/just).

```bash
just status          # what is deployed, and does it match the manifest
just plan            # preview link changes (never mutates)
just apply           # create or repoint symlinks
just check           # the repository gate CI runs
```

## How it works

The [`manifest`](manifest) is the single source of truth. Each row declares a
package, a link mode, a repo-relative source, and a target:

```
PKG          MODE   SOURCE                TARGET
nvim         link   config/nvim           $XDG_CONFIG_HOME/nvim
scripts      tree   bin                   $HOME/.local/bin
claude       tree   home/claude           $HOME/.claude
```

**`link`** places one symlink at the target, so new files inside the source
appear automatically. Use it when the directory is exclusively ours.

**`tree`** creates real directories and links each tracked file individually.
Use it when the tool writes state into the same directory it reads config from
(`~/.config/opencode` also holds `node_modules/`), or when the target is shared
with other installers (`~/.local/bin` has 48 entries; three are ours).

Nothing is inferred. Both the package name and the link shape are declared,
because both were previously inferred and both were wrong — see
[`docs/migration.md`](docs/migration.md).

### Files are enumerated with `git ls-files`

This is the load-bearing decision. `.gitignore` is the repo's **only** ignore
list: an untracked file is never deployed, and there is no second ignore syntax
to keep in sync.

The consequence is a rule that applies to every source directory:

> **A source directory contains only deployable content.**

Documentation therefore lives in [`docs/`](docs/README.md) as `docs/<pkg>.md`,
never inside a source. A `README.md` in `config/nvim/` would deploy to
`~/.config/nvim/README.md`.

## Layout

| Directory | Deploys to | Contents |
| --- | --- | --- |
| [`config/`](config/README.md) | `$XDG_CONFIG_HOME` (`~/.config`) | Tools that respect XDG |
| [`home/`](home/README.md) | `$HOME` | Tools that don't — stored undotted (`home/gitconfig` → `~/.gitconfig`) |
| [`data/`](data/README.md) | `$XDG_DATA_HOME` (`~/.local/share`) | Fonts, shell completions |
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

22 packages across 25 manifest rows. `just packages` lists them; each is
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
[agent-skills](docs/agent-skills.md), [opencode](docs/opencode.md),
[pi](docs/pi.md), [openspec](docs/openspec.md), plus documentation-only notes
for [codex](docs/codex.md), [agy](docs/agy.md), and [serena](docs/serena.md).

**Desktop & misc** — [qutebrowser](docs/qutebrowser.md), [fonts](docs/fonts.md),
[scripts](docs/scripts.md), [kanata](docs/kanata.md) (keyboard remapping).

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
- **Every package is documented** in `docs/<pkg>.md`, covering what it is, where
  it deploys, how to activate it, and any external dependencies.
  `_dots/checks/verify-readmes.sh` enforces this against the manifest.

## Setup on a new machine

Written for **Pop!_OS / Debian** (apt, GNU coreutils, Linux x86_64). Package
names differ elsewhere — notably `fd-find` provides `fdfind` and `bat` provides
`batcat`; the bash config accounts for these. Helper scripts assume Linux
x86_64 + apt/sudo.

```bash
sudo apt install just
git clone <repo> ~/.dots
cd ~/.dots

just plan            # preview every link
just apply           # deploy

# shell/ is sourced, not linked — wire it into ~/.bashrc by hand. Use the
# snippet in shell/README.md, which warns instead of failing silently if the
# loader ever goes missing. This is the one step `just apply` cannot do.
cp shell/local.sh.example shell/local.sh   # then edit for this machine
cp home/gitconfig.local.example ~/.gitconfig.local
```

`just apply` refuses to overwrite an existing real file, reporting it as a
conflict rather than clobbering it. Back it up and remove it, then re-run.

Packages needing activation beyond linking (starship enablement, `fc-cache` for
fonts, TPM for tmux, first-run order for nvim/pi/opencode) document it in their
own `docs/<pkg>.md`.

## Adding a package

1. Create the source directory under `config/`, `home/`, `data/`, or `bin/`,
   containing **only** deployable content.
2. Add a manifest row, choosing `link` or `tree` (see the manifest header).
3. Write `docs/<pkg>.md`.
4. `just plan <pkg>` to preview, then `just apply <pkg>`.
5. `just check` to confirm the gate stays green.

## History

This repo used GNU Stow until August 2026. The move off it, why it happened,
and the bugs the migration surfaced are recorded in
[`docs/migration.md`](docs/migration.md) — worth reading before changing how
deployment works, because most of the design here is a reaction to a specific
failure of Stow's implicit behaviour.

## Implement next/later

See [`TODO.md`](TODO.md).
