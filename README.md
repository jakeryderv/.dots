# dotfiles

My personal dotfiles for Pop!_OS / bash. Configuration is deployed as symlinks
from a declarative [`dots.toml`](dots.toml) by [`dots`](dots.py); the
software sources and install methods are recorded in
[`docs/software.md`](docs/software.md). Language runtimes and package managers
use upstream installations; formatters and linters use uv, Cargo, apt and npm.
Everyday CLI tools use official apt repositories and release downloads.
Editor and shell tools use upstream releases and plugin clones. Kanata uses
its upstream release, QMK uses uv, and `dots` runs on system Python.

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

### Config is linked; software sources are documented

`dots apply` links configuration and the `dots` command. Install software using
[the software inventory](docs/software.md), which records each tool's official
installation docs and update method. No package manager is required beyond
those used by the tools you choose to install.

## Layout

| Path | Purpose |
| --- | --- |
| [`dots.toml`](dots.toml) | What deploys where |
| [`config/`](config/README.md) | One directory per package, deployable content only |
| [`docs/`](docs/README.md) | One file per package |
| [`dots.py`](dots.py) | The `dots` tool: deployer, validator, gate, doctor |
| [`tests/`](tests/README.md) | Behaviour tests for `dots.py` |
| [`docs/software.md`](docs/software.md) | Tool sources, installation methods and local conventions |
| [`tools/`](tools/README.md) | Historical packaging notes; no maintained installer scripts |
| [`_wallpapers/`](_wallpapers/README.md) | Wallpaper / terminal background images |

Only `config/` is ever deployed, and only the parts `dots.toml` names. The `_`
prefix on the rest is a readability convention, not a mechanism.

## Packages

`dots packages` lists them; each is documented in [`docs/`](docs/README.md).

**Terminals** — [ghostty](docs/ghostty.md) (daily driver),
[alacritty](docs/alacritty.md), [kitty](docs/kitty.md),
[wezterm](docs/wezterm.md). All four pin the same font (0xProto Nerd Font Mono)
and a Nightfox-family theme; a font or theme change must be mirrored in each.

**Editors & shell** — [shell](docs/shell.md) (shared by every shell),
[bash](docs/bash.md), [zsh](docs/zsh.md), [nvim](docs/nvim.md), [vim](docs/vim.md),
[tmux](docs/tmux.md), [starship](docs/starship.md), [git](docs/git.md),
[bat](docs/bat.md), [direnv](docs/direnv.md),
[editorconfig](docs/editorconfig.md), [tealdeer](docs/tealdeer.md).

**Coding agents** — [claude](docs/claude.md), [opencode](docs/opencode.md),
[agent-skills](docs/agent-skills.md) (skills shared by every agent),
[herdr](docs/herdr.md) (terminal workspace manager).

**Desktop & misc** — [fonts](docs/fonts.md),
[scripts](docs/scripts.md), [dots](docs/dots.md),
[kanata](docs/kanata.md) (keyboard remapping).

## Conventions

- **[`.editorconfig`](.editorconfig) is the indentation source of truth** —
  4-space default, 2 for lua/web/markdown, tabs for Makefiles. Neovim reads it
  natively, and so do the formatters conform runs (`stylua`, `prettierd`,
  `shfmt`), so the editor and the formatters can't drift apart. It is a
  root-level file, not a package, so it is never deployed. The
  [`editorconfig`](docs/editorconfig.md) package deploys the same rules to
  `~/.editorconfig` as a fallback for projects that ship no config of their own.
- **[`.shellcheckrc`](.shellcheckrc) configures ShellCheck once**, for both the
  editor (via bash-language-server) and CI (`dots check`), so
  diagnostics match what the gate enforces.
- **Formatting is enforced in CI, per language, with no flags.** `shfmt` for
  bash, `stylua` for Lua, `ruff` for Python; each reads the same config the
  editor's format-on-save reads. CI pins upstream Ruff and StyLua and uses
  Ubuntu packages for ShellCheck/shfmt; verify changes with `dots check`.
  Bulk reformats belong in their own commit, listed in
  [`.git-blame-ignore-revs`](.git-blame-ignore-revs).
- **CI uses Ubuntu 24.04 and upstream releases.** The [workflow](.github/workflows/ci.yml)
  installs only the gate's tools, then runs `python3 dots.py check`. Machine
  software remains documented in the inventory, without custom installers.
- **Every package is documented** in `docs/<pkg>.md`, covering what it is, where
  it deploys, how to activate it, and any external dependencies.
  `dots validate` enforces this against `dots.toml`.

## Setup on a new machine

Written for **Pop!_OS / Debian** (apt, GNU coreutils, Linux x86_64). Helper
commands assume Linux x86_64 + apt/sudo.

Install the distro prerequisites first. Git is needed before cloning; the C
compiler and make are needed by Neovim's plugin/parser builds. Python 3.11+
is needed by `dots.py`; Pop!_OS 24.04 supplies Python 3.12.

```bash
sudo apt update
sudo apt install git curl ca-certificates xz-utils tar unzip python3 build-essential
```

The [software inventory](docs/software.md#everyday-cli-tools) records the
preferred upstream sources for Git and the other CLI tools. `bat` uses an
official `.deb` under its canonical name; `fd` uses an upstream archive.
The distro's `fd-find` stays for `pop-launcher` dependencies and provides the
separate `fdfind` name. The guarded `batcat` alias is only a distro fallback.

```bash
git clone https://github.com/jakeryderv/.dots.git ~/.dots
cd ~/.dots

# Bootstrap directly with Python, before the dots command has been linked.
python3 dots.py plan              # preview links and existing-file conflicts
```

Back up existing files reported as conflicts before applying. For example,
on a fresh distro installation, move its Bash configuration aside (the `-i`
prompts before replacing an existing backup):

```bash
mv -i ~/.bashrc ~/.bashrc.pre-dots
python3 dots.py apply

cp config/shell/local.sh.example config/shell/local.sh   # then edit for this machine
cp config/git/gitconfig.local.example ~/.gitconfig.local
```

Edit both copied files for this machine, including your Git identity. On an
existing machine, preserve and review any local files instead of replacing
them with the examples. `dots apply` refuses to overwrite a real file; resolve
any remaining conflicts and re-run it.

Open a new Bash or Zsh session to load the shared environment and its PATH.
Finish the setup steps for the tools you use:

- [Language tools and npm CLIs](docs/software.md): install uv, rustup, Bun,
  Go and nvm from upstream, then install Node and its global packages. Do not
  configure an npm prefix; nvm owns the package location for each Node version.
- [Zsh](docs/zsh.md): install the distro shell and select it with `chsh` if
  desired; install its upstream plugin clones using the software inventory.
- [Neovim](docs/nvim.md#first-run-order), [tmux](docs/tmux.md#external-dependencies),
  and [fonts](docs/fonts.md): install the upstream binaries, plugins and refresh
  the font cache.
- [Kanata](docs/kanata.md): review the machine's keyboard configuration and
  complete the permissions and service setup before enabling it.
- GUI applications and standalone agent CLIs remain separate installs; see
  the relevant [package docs](docs/README.md). Authentication is per machine.

Run `dots deps` to inventory commands and `dots doctor` after activation
to check the deployed links, PATH, and machine setup. These checks do not
install missing software. Tool updates are documented in the software inventory.

## The `dots` tool

[`dots.py`](dots.py) is one standard-library Python file: the deployer, the
validator, the repository gate, and the machine doctor, behind one CLI. The
`dots` on `PATH` is a symlink to the live script, deployed by the `dots`
package. Its Python 3.11+ interpreter comes from `python3` on PATH. Every
command works from any directory; `--repo` or `DOTS_REPO` can select another
checkout. Before deployment, `python3 dots.py` is the same tool.

```bash
dots status          # every entry: does the target resolve into the repo?
dots plan            # dry-run every entry (never mutates)
dots apply           # create or repoint symlinks
dots plan vim        # scope any of these to one package
dots diff            # content differences for targets that drifted
dots unlink          # remove symlinks that resolve into this repo
dots validate        # dots.toml and the documentation rules (repo only)
dots check           # the full gate CI runs: validate, linters, formatters, tests
dots doctor          # health checks against this machine
dots deps            # required/optional external command check
dots packages        # package names dots.toml knows about
dots tools           # installers under tools/
dots install NAME    # run tools/install-NAME.sh
```

The line between `check` and `doctor` is what they may look at: `check` reads
only the repository, so CI runs it on a bare checkout; `doctor` inspects the
live machine — `$HOME`, shell wiring, deployed links, and the command on
`PATH` — and runs `check` as one of its steps.

Two behaviours are enforced rather than documented. A real file at a target is
a conflict: `apply` reports it and moves on, never overwrites; a stale symlink
is repointed, because a symlink carries no content to lose. An unknown package
name is an error: filtering to a name that matches nothing would turn any
command into a silent no-op, so it exits 2 instead.

Tests live in [`tests/`](tests/README.md) and drive the real CLI against a
fixture repo; `dots check` runs them, and `ruff` gates the Python from
[`ruff.toml`](ruff.toml), the one config the editor reads too.

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
