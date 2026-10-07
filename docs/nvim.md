# nvim

Personal Neovim config (Lua, `lazy.nvim`). Deployed to `~/.config/nvim/`.

## Plugin management

All plugins are managed by lazy.nvim. Specifications live in
`lua/lazy_plugins/`, imported as `lazy_plugins`. The import name `lazy` is
reserved by lazy.nvim.

Manage plugins with `:Lazy` and track `lazy-lock.json`. mini.nvim enables
`mini.ai` and `mini.surround`.

## Requirements

- **Neovim ≥ 0.12** — the config uses modern APIs (`vim.lsp.config()` /
  `vim.lsp.enable()`, `vim.hl.on_yank()`, `vim.o.winborder`,
  `client:supports_method()`). Installed from an
  [official release archive](software.md#editor-and-shell-tools).
- **git**, **curl** — plugin + tool fetching.
- A **Nerd Font** (the repo ships `0xProto Nerd Font`; see root README for
  `fc-cache`/`fc-match`). Icons assume `vim.g.have_nerd_font`.

## First-run order

Plugins install on first launch via `lazy.nvim`; Mason then
installs the language servers. Install the [distro prerequisites](../README.md#setup-on-a-new-machine)
and the [editor tools](software.md#editor-and-shell-tools) first. Neovim and
`tree-sitter` use official releases; the C compiler and make come from the
distro's `build-essential`. Recommended
sequence on a fresh machine:

1. `nvim` — let `lazy.nvim` finish installing plugins, then quit.
2. `nvim` again — Mason auto-installs the LSP servers listed below. Wait for
   `:Mason` / fidget to report done. Restart. Install the separate
   [formatters and linters](software.md#formatters-and-linters) too;
   `tree-sitter` is installed from its official release too.
3. `:TSUpdate` — build/refresh Treesitter parsers.

## Tooling ownership

Mason owns language servers, except `ty`, installed with uv, and `rust-analyzer`,
which rustup provides so it matches the active toolchain. Formatters and linters are global tools installed
using the methods in [the software inventory](software.md#formatters-and-linters).
Neovim and local `dots check` resolve the same tools through PATH. CI uses
Ubuntu packages and pinned upstream releases; see the software inventory.

| Tool | Owner | Notes |
|------|-------|-------|
| LSP servers: `lua_ls`, `bashls`, `html`, `cssls`, `emmet_language_server`, `vtsls`, `clangd`, `docker_language_server`, `jsonls`, `yamlls`, `tombi`, `markdown_oxide` | Mason (`mason-lspconfig`) | auto-installed; `tombi` also formats TOML; `markdown_oxide` settings are the [moxide](moxide.md) package |
| `ty` (Python LSP + type checking) | uv tool | `~/.local/bin/ty`; install with `uv tool install ty` |
| `rust-analyzer`, `rustfmt` | rustup components | `rustup component add rust-analyzer`; `rustfmt` ships with the default profile |
| `clang-format` | normal apt | C/C++ formatting, only in projects with a `.clang-format` |
| `actionlint` | [official release](software.md#formatters-and-linters) | GitHub workflow linting; runs ShellCheck on `run:` blocks |
| `stylua` | Cargo | installed with the Lua syntax variants enabled |
| `shfmt`, `shellcheck` | normal apt | shared by the editor and local `dots check` |
| `prettierd`, `eslint_d` | npm under nvm | installed under both Node 24 and Node 22; install them for each Node version used to launch Neovim |
| `tree-sitter` CLI | [official release](software.md#editor-and-shell-tools) | builds parsers; Mason owns language servers |
| **`ruff`** (Python format + lint) | uv tool | `~/.local/bin/ruff` |

## Python

[ty](https://docs.astral.sh/ty/editors/#neovim) is the Python language server,
providing type diagnostics, completion, hover, navigation, renaming and signature
help. It runs `ty server` from PATH and is enabled outside Mason. Pyright is no
longer enabled or requested from Mason.

Ruff's language server (`ruff server`, from the same uv-installed `ruff`) runs
alongside ty for lint diagnostics as you type, with quick fixes on **g r a**
(fix this, fix all, add `# noqa`). Its hover is disabled so **K** shows ty's.
Conform still organizes imports and formats Python on save, or with
**Space c f**; nvim-lint no longer runs Ruff. Blink displays ty's
completion suggestions; LuaSnip and Treesitter keep their existing configuration.

ty [discovers the environment](https://docs.astral.sh/ty/modules/#python-environment)
from `VIRTUAL_ENV`, otherwise from a `.venv` in the project root or working
directory. For uv projects, launch with `uv run nvim` or activate `.venv` before
launching Neovim. An explicit interpreter can be configured with
`[tool.ty.environment]` / `python` in the project's `pyproject.toml`, or
`[environment]` / `python` in `ty.toml`; the former Pyright-specific interpreter
command does not apply to ty.

## Rust

[rustaceanvim](https://github.com/mrcjkb/rustaceanvim) starts rust-analyzer
(from PATH, so rustup's) instead of nvim-lspconfig; enabling `rust_analyzer` in
`lsp.lua` as well would attach a second instance. Its client is named
`rust-analyzer` (hyphen), which is what `LspAttach` checks to turn inlay hints
on. Checks run `cargo clippy`. Rust buffers add **Space r** commands:

| Keys | Command |
| --- | --- |
| **Space r r** / **Space r t** | pick and run a runnable / test in a terminal |
| **Space r m** | expand the macro under the cursor |
| **Space r e** / **Space r d** | explain the error / render the diagnostic as cargo prints it |
| **Space r c** / **Space r p** | open `Cargo.toml` / the parent module |

[crates.nvim](https://github.com/saecki/crates.nvim) loads with `Cargo.toml`.
It marks outdated dependencies, completes crate versions and features through
its in-process language server (so blink's `lsp` source picks them up), and
offers upgrade actions on **g r a**. tombi still validates and formats the file.

## External (non-Mason) dependencies

These features need system binaries and are **not** installed by Mason:

- **A C compiler and `make`** (`cc`, from apt's `build-essential`) — the one
  that actually breaks a fresh install. nvim-treesitter compiles every parser,
  and `telescope-fzf-native` has `build = 'make'`; without them both fail
  quietly and searching degrades to the pure-Lua sorter.
- **`curl` and `tar`** (apt) — nvim-treesitter fetches and unpacks each grammar
  before compiling it. `:checkhealth nvim-treesitter` reports all four of these
  together, and is the fastest way to confirm the parser toolchain is intact.
- **Clipboard** (`clipboard = unnamedplus`) — needs `wl-clipboard` (Wayland) or
  `xclip`/`xsel` (X11). Verify with `:checkhealth provider`.
- **`markdown-preview`** — hard-codes `firefox --new-window` (see
  `markdown-preview.lua`). Needs Firefox on `PATH`, or edit the `browserfunc`.
  Its `build` step also shells out to `node`/`yarn`, which come from
  [nvm and npm](software.md#node-and-npm-tools). Launch Neovim from a shell
  with the intended Node version selected.
- **`img-clip`** — reads the clipboard through `wl-paste` (`wl-clipboard`) on
  Wayland or `xclip` on X11.
- **`inotifywait`** (apt `inotify-tools`, optional) — markdown-oxide asks
  Neovim to watch the vault for file changes. Without `inotifywait`, Neovim on
  Linux falls back to scanning and watching every directory itself, which is
  slower in large repos.

Other plugin dependencies include `rg` and `fd` for Telescope,
and `git` for lazy.nvim clones; these use the
[official CLI installations](software.md#everyday-cli-tools). `tmux` for
vim-tmux-navigator uses an [official prebuilt release](software.md#editor-and-shell-tools).

## Markdown preview

**Space m p** toggles a Firefox preview (markdown-preview.nvim) that follows
the focused Markdown buffer. For a terminal preview, run the [Leaf](leaf.md)
CLI (`leaf --watch FILE`) outside Neovim.

**Space m r** toggles in-buffer rendering (render-markdown.nvim; on by
default). It switches back to raw text on the cursor line and in insert mode.

## Notes (markdown-oxide)

Every git repo is a notes vault; layout and settings are in [moxide.md](moxide.md).
markdown-oxide attaches to Markdown buffers inside a vault and works through
the normal LSP keys:

| Key / command | Action |
|---|---|
| **Space m f** | Telescope: pick a Markdown file, insert a link to it |
| **Space m h** | Telescope: pick a heading anywhere in the repo, insert a link to it |
| `[[` | Complete wikilinks (blink); these do not render on GitHub |
| `<CR>` on a link | Follow it, vault-wide; `gd` also works |
| `grr` | On body text: backlinks to the file. On a heading, link or `#tag`: its references |
| `grn` | Rename a note or heading and update links |
| `gra` | Code actions, e.g. create the file for an unresolved link |
| `gW` | Search notes, headings and tags in the vault |
| **Space m d**, `:Daily [when]` | Daily note: `:Daily yesterday`, `:Daily next monday`, `:Daily -3` |
| **Space m i** | Paste a clipboard image into `notes/assets/` and insert the link |

### GitHub-compatible links

**Space m f** and **Space m h** (`lua/markdown_links.lua`) insert plain
Markdown links whose paths start at the repo root, such as `/docs/guide.md`
or `/docs/guide.md#next-steps`. GitHub resolves a leading `/` from the
repository root, and markdown-oxide resolves the same form, so these links
work in both places. The file name is the link text for files, and the heading
text for headings. In visual mode, the selection becomes the link text.

Both pickers list every `.md` file in the repo that `.gitignore` does not
exclude, so new notes appear before they are committed. Heading anchors follow
GitHub's rules: lowercase, punctuation removed, spaces become `-`, and repeated
headings get `-1`, `-2` suffixes. A heading in the current file is linked as a
bare `#anchor`. Paths containing spaces are wrapped in `<...>`.

`<CR>` asks the language server first. If it finds nothing, it resolves the
link GitHub's way: relative to the current file, or to the repo root with a
leading `/`, then jumps to the `#anchor` heading. That covers `../` links and
anchors the server doesn't match, such as `#setup-1`, as well as files outside
a vault. Links to non-Markdown files open directly, and URLs open in the browser.

## Multiplexer navigation

`Ctrl+h/j/k/l` moves between Neovim splits and the surrounding multiplexer.
Outside Herdr the existing `vim-tmux-navigator` mappings remain unchanged,
including `Ctrl+\` for the previous window/pane.

Inside a Herdr pane, `lua/lazy_plugins/vim-tmux-navigator.lua` asks
`herdr plugin list --plugin vim-herdr-navigation --json` for the installed
plugin root and loads its `editor/nvim.lua`. It uses `HERDR_BIN_PATH` when
provided, otherwise `herdr` on `PATH`. This shares the pinned Herdr checkout
rather than maintaining a second clone/version in lazy.nvim. The lookup has a
two-second timeout and warns if the bridge is missing or disabled.

The tmux plugin loads eagerly with its automatic mappings disabled: the spec
provides the original tmux mappings, then the Herdr bridge replaces only the
four directional mappings inside Herdr. `Ctrl+\` is not remapped by the bridge.
There is no lazy key handler left to replace those mappings on first use.

Install both halves using the [Herdr plugin setup](herdr.md#plugins), then
restart Neovim. Verify movement within an editor split, across an editor edge
to another Herdr pane, and in the separate tmux tab. Bridge mappings are
normal-mode only; insert-mode and Telescope mappings stay unchanged.

## Health checks

```vim
:checkhealth            " overall (providers, deps)
:checkhealth provider   " clipboard/node/python providers
:Lazy health            " plugin manager
:Mason                  " installed tools/servers
:ConformInfo            " formatter status for current buffer
```

Headless sanity check:

```bash
nvim --headless '+checkhealth' '+qa'
```

## Notable choices

- **Code actions**: **g r a** (tiny-code-action.nvim) opens a Telescope
  picker with a delta diff of the highlighted action: type to filter, `<CR>`
  applies. (Its compact buffer picker, with a hotkey per action, is kept
  commented out in `tiny-code-action.lua`.) **g r A** is Neovim's built-in
  menu without a preview, kept as a fallback. In normal mode both cover
  what's under the cursor; prefix **V** for the whole line. (gra also sends
  every diagnostic on the line, but only servers that use that list, like
  Ruff, act on it; rust-analyzer only looks at the cursor or selection.) delta runs
  with `--no-gitconfig`, because the git config's side-by-side layout wraps
  badly in the small preview.
- **Keymap descriptions** follow `Area: action` with no `[B]racket` letters,
  where the area is the which-key group the key sits in (`Search: Files`,
  `Git: Stage hunk`, `LSP: Goto references`; keys outside a group have no
  prefix). Telescope's keymap picker (**Space s k**) shows the full text, and
  which-key strips the prefix because the group title already shows it. A new
  group needs its name added to `AREAS` in `which-key.lua`. Columns are capped
  at 50 characters so long built-in descriptions can't force a single column.
- **Format on save** via `conform.nvim` (`lsp_format = 'fallback'`,
  `timeout_ms = 2000`). C/C++ only formats when a `.clang-format` (or
  `_clang-format`) exists in the file's directory or a parent, so clangd's
  LLVM default is never imposed on other projects. TOML has no conform entry;
  the `tombi` server formats it through the LSP fallback. Markdown is **not**
  formatted: prettier would pad every table, rewriting most of `docs/`.
- **Indentation**: 4-space soft tabs by default (`softtabstop = -1`, so
  `<Tab>`/`<BS>` move a whole step); a `FileType` autocmd drops to 2 for lua,
  the web filetypes, and markdown, matching what `stylua`/`prettierd` emit. A
  project `.editorconfig` is applied *after* that autocmd and overrides it —
  that is the intended precedence. Do **not** add `prepend_args` to the `shfmt`
  formatter: shfmt ignores `.editorconfig` as soon as formatting flags are
  passed.
- **Lint on save/read** via `nvim-lint`. **Shell is not listed there on
  purpose** — `bashls` runs ShellCheck internally, on every change rather than
  only on write, so listing it in `nvim-lint` too surfaced every warning twice.
  Settings live in `~/.dots/.shellcheckrc`, which bashls and CI both read.
  `actionlint` runs only on `.github/workflows/*.yml`, matched by path rather
  than filetype because it rejects other YAML.
- **Rust** checks run `cargo clippy` through rust-analyzer (started by
  rustaceanvim, see [Rust](#rust)), and inlay hints start on in Rust buffers
  (**Space t h** toggles them); **C/C++** runs
  clang-tidy inside clangd (`--clang-tidy`; a project `.clang-tidy` picks the
  checks). clangd needs a `compile_commands.json` for real projects
  (`cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`, or `bear -- make`).
- **Schemas**: `jsonls` and `yamlls` take their catalog from SchemaStore.nvim
  (package.json, tsconfig, GitHub workflows, Compose, …). yamlls's own catalog
  download is disabled so the two can't disagree.
- **Compose files** (`compose*.yml`, `docker-compose*.yml`) get the compound
  filetype `yaml.docker-compose` (set in `options.lua`), so
  `docker_language_server` attaches alongside the normal YAML tooling.
- **zsh** uses the `zsh` Treesitter parser (tier 2, community-maintained). No
  LSP or formatter: bashls, ShellCheck and shfmt don't support zsh.
- `lazy-lock.json` pins plugin versions — commit it when you intentionally
  update plugins (`:Lazy update`).
