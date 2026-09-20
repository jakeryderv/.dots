# Software

An inventory of installation sources and this machine's conventions. Follow
the linked official installation and update documentation; this repo does not
wrap straightforward upstream installations in custom scripts. Record a
special flag or path here only when this configuration depends on it.

Method names: **normal apt** means the distro's existing repositories;
**configured apt** means an added vendor repository; **upstream installer**
means the project's installer; **release archive** means a prebuilt download;
**source build** means compiling the source. An **official .deb** is a release
package downloaded directly from upstream; it does not add an apt repository.
Use one owner per tool.

## Language tools (migrated from Nix)

| Tool | Official project and installation docs | Method | Local installation | Updates |
| --- | --- | --- | --- | --- |
| uv / uvx | [uv](https://docs.astral.sh/uv/), [installation](https://docs.astral.sh/uv/getting-started/installation/), [installer options](https://docs.astral.sh/uv/reference/installer/) | Upstream installer | `~/.local/bin` | `uv self update` |
| rustup / cargo / rustc | [Rust](https://www.rust-lang.org/), [rustup installation](https://rust-lang.github.io/rustup/installation/other.html) | Upstream installer | `${CARGO_HOME:-~/.cargo}/bin`; toolchains under `${RUSTUP_HOME:-~/.rustup}` | `rustup self update` for the manager; `rustup update` for Rust toolchains |
| Bun / bunx | [Bun](https://bun.com/), [installation](https://bun.com/docs/installation) | Upstream installer | `${BUN_INSTALL:-~/.bun}/bin` | `bun upgrade` |
| Go / gofmt | [Go](https://go.dev/), [installation](https://go.dev/doc/install), [downloads and checksums](https://go.dev/dl/) | Official release archive, Linux amd64 | `~/.local/opt/goVERSION`, selected by `~/.local/opt/go`; `go` and `gofmt` links in `~/.local/bin` | Download and verify the new archive, extract into a fresh version directory, then repoint `~/.local/opt/go` |

Group 1 migrated on 2026-09-20, keeping the existing versions: uv **0.12.11**,
rustup **1.29.0**, Bun **1.4.2**, and Go **1.26.7**. These are a migration record,
not version pins; use the official docs to choose future versions.

## Local conventions

- [`config/shell/env.sh`](../config/shell/env.sh) owns PATH for Bash and Zsh,
  including `~/.local/bin`, the Cargo and Bun bin directories, and `~/go/bin`.
  Avoid duplicate PATH blocks from installers. No `GOROOT` override is needed.
- uv: use `UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1` with its
  installer. Python installations, tool environments and caches stay in their
  existing locations under `~/.local/share/uv` and `~/.cache/uv`.
- rustup: pass `--no-modify-path`. When replacing only the manager while
  preserving installed toolchains, also pass `--default-toolchain none`.
  On a new machine, install a default toolchain following the official docs.
- Bun: the installer needs `unzip`. Its `bunx` command uses the same executable
  (`~/.bun/bin/bunx -> bun`). Bun's completion setup can append a source hook
  to `.zshrc`; use the user completion directory below instead of keeping a
  machine-specific or temporary path in the tracked rc file.
- Go: verify the archive against the published SHA-256 and extract into a
  **new** directory, never over an existing Go tree. This host uses a user
  directory rather than the official guide's `/usr/local/go`. Keep the stable
  `~/.local/opt/go` link and its `go`/`gofmt` launcher links when updating.
  Existing modules and `go install` output remain under `~/go`.
- Completions for uv, rustup/Cargo and Bun are installed under
  `${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions` and
  `${XDG_DATA_HOME:-~/.local/share}/zsh/site-functions`. Bash and Zsh already
  search these directories. uv provides `generate-shell-completion`; rustup
  provides `completions`; Bun ships completion files with its releases/source.
  Refresh the generated files when a tool update changes its commands.

The existing Python/Rust toolchains, virtual environments, caches and project
dependencies are independent of these manager installations. Update the
managers and their installed runtimes separately using the official docs.

## Node and npm tools

| Tool/package | Official project and installation docs | Method | Local installation |
| --- | --- | --- | --- |
| nvm | [nvm installation and updates](https://github.com/nvm-sh/nvm#installing-and-updating) | Upstream installer | `~/.nvm`; installed with `PROFILE=/dev/null` so the tracked shell configuration owns initialization |
| Node / npm / npx | [Node](https://nodejs.org/), [nvm usage](https://github.com/nvm-sh/nvm#usage) | nvm (`nvm install VERSION`) | `~/.nvm/versions/node/vVERSION`; default alias is `24` |
| Corepack | [official docs](https://github.com/nodejs/corepack) | Included with the installed Node 22/24 distributions | Present alongside Node; pnpm and Yarn below use direct npm installations, not Corepack shims |
| pnpm | [installation](https://pnpm.io/installation) | npm global: `pnpm@10` | Selected Node's global package directory |
| Yarn Classic | [installation](https://classic.yarnpkg.com/lang/en/docs/install/) | npm global: `yarn@1` | Selected Node's global package directory |
| Pi | [Pi](https://pi.dev), [repository/docs](https://github.com/earendil-works/pi/tree/main/packages/coding-agent) | npm global: `@earendil-works/pi-coding-agent` | Provides `pi` |
| Cloudflare CLI | [package and docs](https://www.npmjs.com/package/cf) | npm global: `cf` | Provides `cf` |
| Wrangler | [installation and updates](https://developers.cloudflare.com/workers/wrangler/install-and-update/) | npm global: `wrangler` | Provides `wrangler` |
| Playwright CLI | [official repository/docs](https://github.com/microsoft/playwright-cli) | npm global: `@playwright/cli` | Provides `playwright-cli`; browsers under `~/.cache/ms-playwright` |
| Mermaid CLI | [official repository/docs](https://github.com/mermaid-js/mermaid-cli) | npm global: `@mermaid-js/mermaid-cli` | Provides `mmdc`; Puppeteer's Chrome under `~/.cache/puppeteer` |

Group 2 migrated on 2026-09-20 with nvm **0.40.7**, default Node **24.20.0** /
npm **11.19.0**, pnpm **10.34.5** and Yarn **1.22.22**. The global CLI versions
were preserved: Pi **0.85.1**, cf **0.8.0**, Wrangler **4.128.0**,
Playwright CLI **0.1.19**, and Mermaid CLI **11.17.0**.

### Node selection

Both Bash and Zsh load nvm from [`env.sh`](../config/shell/env.sh). There is no
automatic directory-change hook. Use `nvm use` in a project with `.nvmrc`, and
`nvm use default` to return to Node 24.

`pi-cli-tools` has `.nvmrc` set to **22.19.0**. That Node installation has npm
**11.9.0**, matching its `packageManager` field. Its former local Nix shell
files and `.direnv` cache were archived under
`~/.local/state/dots-migrations/2026-09-20-node/pi-cli-tools/`.

### npm globals

Do not set `prefix` in `~/.npmrc`: nvm uses the selected Node installation's
writable package directory. The CLI packages in the table above are installed
under Node 24; they are separate from the Node 22 project environment. Use
`nvm use default` before running or updating those CLIs. The editor's
`prettierd` and `eslint_d` are installed under both versions, as described below.
Never use sudo for these installs.

Standard install/update commands, replacing the former custom installer:

```bash
nvm use default
npm install -g --ignore-scripts pnpm@10 yarn@1 @earendil-works/pi-coding-agent cf wrangler
npm install -g @playwright/cli
playwright-cli install-browser chromium
npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli
```

The first group needs no install lifecycle scripts. Playwright needs its browser
installation step. Mermaid needs Puppeteer's browser download; npm 11.19 can
require explicit permission for that postinstall, hence `--allow-scripts` above.
Existing browser caches and CLI authentication are reused; changing Node
installation does not require signing in again.

The old `~/.npm-global` directory is preserved outside PATH at
`~/.local/state/dots-migrations/2026-09-20-node/npm-global/`. That directory also
has a sibling `npmrc.before` backup and the previous package inventory. These
are migration backups, not active installations.

When installing a newer default Node, nvm's
[global-package migration](https://github.com/nvm-sh/nvm#migrating-global-packages-while-installing)
can reinstall these packages. pnpm 10 and Yarn Classic remain the selected
majors; review project requirements before changing them. The pnpm npm package
provides `pnpm` and `pnpx`; the former Nix-only `pn` and `pnx` shortcuts are no
longer installed.

## Formatters and linters

| Tool | Official project and installation docs | Method | Local installation | Updates |
| --- | --- | --- | --- | --- |
| Ruff | [installation](https://docs.astral.sh/ruff/installation/) | uv tool | `~/.local/bin/ruff`; environment managed by uv | `uv tool install ruff@latest` |
| StyLua | [installation](https://github.com/JohnnyMorganz/StyLua#installation) | Cargo source build | `~/.cargo/bin/stylua` | repeat the Cargo command below to select the latest release |
| ShellCheck | [installation](https://github.com/koalaman/shellcheck#installing) | normal apt: `shellcheck` | `/usr/bin/shellcheck` | normal apt updates |
| shfmt | [project and installation](https://github.com/mvdan/sh) | normal apt: `shfmt` | `/usr/bin/shfmt` | normal apt updates |
| prettierd | [installation](https://github.com/fsouza/prettierd#installation-guide) | npm global: `@fsouza/prettierd` | selected Node's bin directory | repeat npm install for each Node version used by Neovim |
| eslint_d | [installation](https://github.com/mantoni/eslint_d.js#setup) | npm global: `eslint_d` | selected Node's bin directory | repeat npm install for each Node version used by Neovim |

Group 3 migrated on 2026-09-20: Ruff **0.16.7**, StyLua **2.5.2**,
prettierd **0.28.0**, and eslint_d **15.0.3**. npm resolved the bundled ESLint
to **10.11.0** (the former Nix build bundled **10.0.3**). ShellCheck **0.9.0**
and shfmt **3.8.0** use the distro versions, replacing Nix's **0.11.0** and
**3.14.1** respectively; both passed the repository's checks.

Standard installation/update commands:

```bash
uv tool install ruff@latest
cargo install stylua --locked --features lua52,lua53,lua54,luajit,luau
sudo apt install shellcheck shfmt

nvm use default
npm install -g --ignore-scripts @fsouza/prettierd eslint_d
nvm use 22.19.0
npm install -g --ignore-scripts @fsouza/prettierd eslint_d
nvm use default
```

Ruff was initially installed at the recorded version; `ruff@latest` also
replaces that installation constraint when upgrading. StyLua's extra features
preserve support for the Lua syntax variants beyond its default Lua 5.1 build.

The two npm tools are deliberately installed under **both existing Node
versions**. Launch Neovim from the shell after selecting the intended version.
When adding a Node version, install these two packages there too or migrate
them with nvm; no hard-coded Node paths or custom launchers are needed.
The npm packages need no install lifecycle scripts. Both can use a project's
local Prettier/ESLint when present, falling back to their bundled versions.

Mason continues to own language servers; do not install duplicate copies of
these six tools through Mason. CI uses the same formatting rules with pinned
upstream Ruff/StyLua and Ubuntu's ShellCheck/shfmt; see below.

## Everyday CLI tools

| Tool | Official source and installation docs | Method | Local installation / updates |
| --- | --- | --- | --- |
| Git | [Git Linux installation](https://git-scm.com/install/linux) | configured apt: `ppa:git-core/ppa`, recommended by Git's Ubuntu instructions | `/usr/bin/git`; normal apt updates after adding the PPA |
| GitHub CLI (`gh`) | [official apt setup](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) | configured apt: `https://cli.github.com/packages` | `/usr/bin/gh`; apt updates |
| Glow | [official apt setup](https://github.com/charmbracelet/glow#installation) | configured apt: `https://repo.charm.sh/apt/` | `/usr/bin/glow`; apt updates |
| Delta | [installation](https://dandavison.github.io/delta/installation.html), [releases](https://github.com/dandavison/delta/releases) | official `.deb`: `git-delta_VERSION_amd64.deb` | `/usr/bin/delta`; download a newer package and install it with apt |
| ripgrep (`rg`) | [installation](https://github.com/BurntSushi/ripgrep#installation), [releases](https://github.com/BurntSushi/ripgrep/releases) | official `.deb`: `ripgrep_VERSION_amd64.deb` | `/usr/bin/rg`; download a newer package and install it with apt |
| bat | [installation](https://github.com/sharkdp/bat#installation), [releases](https://github.com/sharkdp/bat/releases) | official `.deb`: `bat_VERSION_amd64.deb` | `/usr/bin/bat`; download a newer package and install it with apt |
| fd | [releases](https://github.com/sharkdp/fd/releases) | official release archive: Linux x86_64 GNU | `~/.local/bin/fd`; replace from a newer archive |
| Lazygit | [installation](https://github.com/jesseduffield/lazygit#installation), [releases](https://github.com/jesseduffield/lazygit/releases) | official release archive: Linux x86_64 | `~/.local/bin/lazygit`; replace from a newer archive |
| fzf | [binary releases and shell integration](https://github.com/junegunn/fzf#binary-releases) | official release archive: Linux amd64 | `~/.local/bin/fzf`; replace from a newer archive; also refresh `fzf-tmux` from the matching upstream tag |
| ast-grep | [releases](https://github.com/ast-grep/ast-grep/releases) | official release archive: Linux x86_64 GNU | `~/.local/bin/ast-grep`; replace from a newer archive |
| Just | [prebuilt binaries](https://just.systems/man/en/pre-built-binaries.html) | official release archive: Linux x86_64 musl | `~/.local/bin/just`; replace from a newer archive |
| Tealdeer (`tldr`) | [project/docs](https://github.com/tealdeer-rs/tealdeer), [releases](https://github.com/tealdeer-rs/tealdeer/releases) | official binary: Linux x86_64 musl | `~/.local/bin/tldr`; replace from a newer release |

Group 4 migrated on 2026-09-20: Git **2.55.0**, gh **2.101.0**, Glow **3.0.0**,
Delta **0.19.2**, ripgrep **15.2.0**, bat **0.26.1**, fd **10.5.0**,
Lazygit **0.65.1**, fzf **0.74.4**, ast-grep **0.45.1**, Just **1.58.0**,
and Tealdeer **1.9.0**. All retained their previous versions except gh,
which moved from **2.100.0** to the official repository's **2.101.0**.
The verified release URLs and SHA-256 digests are recorded locally in
`~/.local/state/dots-migrations/2026-09-20-cli/verified-downloads.json`.

### Installation and updates

For Git, gh and Glow, follow the linked repository setup instructions once.
Use `noble` on this Pop!_OS 24.04 machine when an Ubuntu codename is needed.
The GitHub and Charm sources use separate keys in `/etc/apt/keyrings` with
`signed-by` on their source entries. Then install/update with:

```bash
sudo apt update
sudo apt install git gh glow
```

For Delta, ripgrep and bat, download the Linux amd64 `.deb` from the linked
upstream release page, verify its published checksum/digest, and run:

```bash
sudo apt install ./DOWNLOADED_PACKAGE.deb
```

These local `.deb` installations are tracked by apt/dpkg, but **do not create
an upstream update feed**. Updating means downloading a newer release package.

For archives, download and verify the release for this machine, extract it,
and install the executable with `install -m 755 PATH_TO_BINARY ~/.local/bin/`.
Rename the Tealdeer release binary to `~/.local/bin/tldr`. Install `ast-grep`
from its archive; its alternate `sg` executable is not installed here, preserving
the system's existing `sg` command. The distro's `fd-find` stays installed for
Pop!_OS dependencies; the upstream tool provides the separate `fd` command.

### Completions, manuals and integrations

- Apt/.deb packages supply system completion and man-page files where included.
  Zsh also searches `/usr/share/zsh/site-functions` for Glow's apt completion.
  Delta's `.deb` does not include completions; generate them with
  `delta --generate-completion bash` and `delta --generate-completion zsh`.
- The fd and Just archives include Bash/Zsh completions and man pages.
  Tealdeer publishes completion files alongside its binary. ast-grep generates
  them with `ast-grep completions bash` / `ast-grep completions zsh`;
  Lazygit uses `lazygit completion bash` / `lazygit completion zsh`.
- Put user Bash completions under
  `~/.local/share/bash-completion/completions/COMMAND`, Zsh completions under
  `~/.local/share/zsh/site-functions/_COMMAND`, and manuals under
  `~/.local/share/man/man1/`. Refresh these alongside each binary update.
- fzf embeds the existing `fzf --bash` / `fzf --zsh` hooks. Its separate
  `bin/fzf-tmux` helper and `man/man1/fzf*.1` manuals come from the same
  tagged [upstream source](https://github.com/junegunn/fzf). The Nix-specific
  `fzf-share` helper is retired; this config does not use it.
- Git's standard helpers follow the apt package layout (`/usr/bin` and
  `git --exec-path`). The unused Nix-added `git-jump`, `git-credential-netrc`
  and `git-cvsserver` commands are no longer on PATH. Git's contrib scripts
  remain under `/usr/share/doc/git/contrib`; CVS server support is a separate
  apt package if ever needed.
- Preserve the [bat theme cache](bat.md) used by Delta. Rebuild it with
  `bat cache --build` when upgrading bat, then verify both `bat` and `delta`
  still recognize `carbonfox`.

## Editor and shell tools

| Tool | Official source and installation docs | Method | Local installation / updates |
| --- | --- | --- | --- |
| Neovim | [installation](https://github.com/neovim/neovim/blob/master/INSTALL.md#linux), [releases](https://github.com/neovim/neovim/releases) | official Linux x86_64 release archive | complete runtime under `~/.local/opt/nvimVERSION`; stable `~/.local/opt/nvim` link, `~/.local/bin/nvim` launcher link |
| Tree-sitter CLI | [releases](https://github.com/tree-sitter/tree-sitter/releases) | official `tree-sitter-linux-x64.gz` binary | `~/.local/bin/tree-sitter`; replace from a newer verified release |
| tmux | [official prebuilt releases](https://github.com/tmux/tmux-builds) | official Linux x86_64 release archive | `~/.local/bin/tmux`; replace from a newer verified release |
| Starship | [installation](https://starship.rs/guide/) | official installer | `~/.local/bin/starship`; rerun the upstream installer to update |
| direnv | [installation](https://direnv.net/docs/installation.html), [releases](https://github.com/direnv/direnv/releases) | official `direnv.linux-amd64` binary | `~/.local/bin/direnv`; replace from a newer verified release |

Group 5 migrated on 2026-09-20, preserving Neovim **0.12.5**, Tree-sitter
**0.26.11**, tmux **3.7c**, Starship **1.26.0**, and direnv **2.37.1**.
Installed Zsh plugin revisions are listed below. Release digests and plugin
commit IDs are recorded locally under
`~/.local/state/dots-migrations/2026-09-20-editor-shell/`.

### Installation and updates

Keep Neovim's **whole extracted directory**, including its runtime files.
Extract a new release into a new `~/.local/opt/nvimVERSION` directory, then
repoint `~/.local/opt/nvim` to it. The stable launcher link is
`~/.local/bin/nvim -> ../opt/nvim/bin/nvim`. The manual link under
`~/.local/share/man/man1/nvim.1` points through the same stable directory.
Existing configuration, Lazy plugins, Mason language servers and installed
Tree-sitter parsers remain in their normal user directories.

Install Tree-sitter, tmux and direnv with `install -m 755` into `~/.local/bin`
after downloading and verifying the matching official release. Tree-sitter's
`.gz` file decompresses to one executable. Use tmux's stable release builds,
not its preview builds. Test tmux changes on a separate `tmux -L NAME` server;
existing servers keep their running binary until their sessions end.

For Starship, use the official installer with the user bin directory:

```bash
curl -fsSL https://starship.rs/install.sh -o /tmp/starship-install.sh
sh /tmp/starship-install.sh --bin-dir "$HOME/.local/bin"
```

The tracked Bash/Zsh rc files already initialize Starship, direnv and fzf.
Avoid adding duplicate hooks to `local.sh`. Refresh Starship completions with
`starship completions bash` / `starship completions zsh`; Tree-sitter uses
`tree-sitter complete --shell bash` / `tree-sitter complete --shell zsh`.
Install those outputs in the existing user completion directories. tmux and
direnv manuals come from the corresponding tags in their official source
repositories and live under `~/.local/share/man/man1`.

### Zsh plugins

Each plugin is an ordinary clone of its official repository, checked out at a
release tag under `${XDG_DATA_HOME:-~/.local/share}/zsh/plugins/REPO_NAME`.
No plugin manager or custom installer is involved.

| Plugin/source | Installed tag | Purpose |
| --- | --- | --- |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | `v0.7.1` | command suggestions |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | `0.36.0` | extra completions, including nvm |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | `v1.3.0` | fuzzy completion menu |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | `v1.1.0` | history matching with Up/Down |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | `0.8.0` | command-line highlighting |

Example installation (substitute the corresponding URL, tag and directory
for each table row):

```bash
git clone --depth 1 --branch v0.7.1 \
  https://github.com/zsh-users/zsh-autosuggestions.git \
  ~/.local/share/zsh/plugins/zsh-autosuggestions
```

To update a plugin, fetch the desired release tag and check it out with
`git checkout --detach TAG` in that clone, then open a fresh shell. Record the
new revision in this inventory. Because these clones are at release tags,
`git pull` is not the update method.

Zsh adds `zsh-completions/src` to `fpath` before `compinit` and sources the
other plugins in their existing order. fzf-tab uses its pure-Zsh fallback;
its optional C module is not built. Plugin configuration stays in the tracked
[Zsh rc file](../config/zsh/zshrc).

### direnv and retired Nix integration

direnv remains for ordinary `.envrc` files and the `use_gh_account` helper.
The global nix-direnv hook and package were removed. The active work project
`.envrc` files found in `winch-cad` and `winch-lab` use only the GitHub-account
helper. Plugin development checkouts contain some upstream Nix examples;
those files are not runtime dependencies and were left untouched.

Project Python environments use uv; Node version selection uses explicit
`nvm use`. This dotfiles configuration no longer loads nix-direnv's flake
caching extension. See [direnv configuration](direnv.md).

## Keyboard tools and dots

| Tool | Official source and installation docs | Method | Local installation / updates |
| --- | --- | --- | --- |
| Kanata | [project](https://github.com/jtroo/kanata), [releases](https://github.com/jtroo/kanata/releases) | Official Linux x64 release zip, **non-cmd** binary | Install `kanata_linux_x64` as `~/.local/bin/kanata`; download and verify a new release, validate the config, then restart the user service |
| QMK CLI | [CLI docs](https://docs.qmk.fm/cli), [official bootstrapper](https://install.qmk.fm), [Python package](https://pypi.org/project/qmk/) | `uv tool install --python /usr/bin/python3 --with pip qmk` on this already provisioned host | `~/.local/bin/qmk`, environment under `~/.local/share/uv/tools/qmk`; update with `uv tool install --python /usr/bin/python3 --with pip --upgrade 'qmk@latest'` |
| dots | [repository CLI](dots.md) | Symlink deployed by `python3 dots.py apply dots` | `~/.local/bin/dots` points to the live `dots.py`; requires Python 3.11+ on PATH |

Group 6 migrated on 2026-09-20, preserving Kanata **1.12.0** and QMK
**1.2.0**. Kanata's systemd unit uses the new binary path; its keymap, device
allowlist, permissions and non-cmd build are unchanged. Validate before every
service restart:

```bash
kanata --cfg ~/.config/kanata/kanata.kbd --check
systemctl --user daemon-reload    # needed when the unit changes
systemctl --user restart kanata.service
```

QMK's existing toolchains and flashing utilities remain under
`~/.local/share/qmk`. The CLI was installed with `qmk==1.2.0` to preserve its
version, with pip available for firmware setup as in the official bootstrapper;
use `uv tool install --with pip --upgrade 'qmk@latest'` to remove that version
constraint when ready to update. There is no configured firmware checkout on
this host, so migration checks cover the CLI and compiler binaries, not a
firmware build or device flash.

For a **new machine**, use QMK's official bootstrapper from its CLI docs. It
installs uv, the CLI, toolchains, flashing utilities and Linux udev rules;
installing the Python package alone does not provision all of those. Follow
`qmk setup` for your intended firmware repository and its Python dependencies.
Do not replace an existing firmware checkout or toolchain directory as part
of a CLI-only update.

Migration records are under
`~/.local/state/dots-migrations/2026-09-20-final/`. The host's Nix uninstall was
completed and verified after a fresh login; see [the cleanup record](nix-removal.md).

## CI prerequisites

The [CI workflow](../.github/workflows/ci.yml) uses Ubuntu **24.04**, installing
ShellCheck, shfmt, Lua 5.4, Zsh and Python's venv support through normal apt.
Ruff **0.16.7** is installed in a temporary Python environment. StyLua **2.5.2**,
the non-cmd Kanata **1.12.0** binary and Neovim **0.12.5** come from official
release archives with fixed SHA-256 checksums. Neovim runs the Herdr loader
test without user configuration. Update each version and checksum together.
CI runs `python3 dots.py check` directly, without deploying personal dotfiles.

The workflow is the only automated installation needed for the gate; machine
installations continue to follow the linked upstream documentation. There are
no maintained installer scripts in [tools/](../tools/README.md).
