# nvim

Personal Neovim config (Lua, `lazy.nvim`). Deployed to `~/.config/nvim/`.

## Requirements

- **Neovim ≥ 0.12** — the config uses modern APIs (`vim.lsp.config()` /
  `vim.lsp.enable()`, `vim.hl.on_yank()`, `vim.o.winborder`,
  `client:supports_method()`). It has a runtime fallback for `nvim-0.11`, but is
  developed and tested against 0.12. Installed from an [official release archive](software.md#editor-and-shell-tools).
- **git**, **curl** — plugin + tool fetching.
- A **Nerd Font** (the repo ships `0xProto Nerd Font`; see root README for
  `fc-cache`/`fc-match`). Icons assume `vim.g.have_nerd_font`.

## First-run order

Plugins install on first launch via `lazy.nvim`; Mason then installs the
language servers. Install the [distro prerequisites](../README.md#setup-on-a-new-machine)
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

Mason owns language servers. Formatters and linters are global tools installed
using the methods in [the software inventory](software.md#formatters-and-linters).
Neovim and local `dots check` resolve the same tools through PATH. CI uses
Ubuntu packages and pinned upstream releases; see the software inventory.

| Tool | Owner | Notes |
|------|-------|-------|
| LSP servers: `lua_ls`, `bashls`, `pyright`, `html`, `cssls`, `emmet_language_server`, `vtsls` | Mason (`mason-lspconfig`) | auto-installed |
| `stylua` | Cargo | installed with the Lua syntax variants enabled |
| `shfmt`, `shellcheck` | normal apt | shared by the editor and local `dots check` |
| `prettierd`, `eslint_d` | npm under nvm | installed under both Node 24 and Node 22; install them for each Node version used to launch Neovim |
| `tree-sitter` CLI | [official release](software.md#editor-and-shell-tools) | builds parsers; Mason owns language servers |
| **`ruff`** (Python format + lint) | uv tool | `~/.local/bin/ruff` |

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

Other plugin dependencies include `rg` and `fd` for Telescope, `lazygit`,
and `git` for lazy.nvim clones; these use the
[official CLI installations](software.md#everyday-cli-tools). `tmux` for
vim-tmux-navigator uses an [official prebuilt release](software.md#editor-and-shell-tools).

## Multiplexer navigation

`Ctrl+h/j/k/l` moves between Neovim splits and the surrounding multiplexer.
Outside Herdr the existing `vim-tmux-navigator` mappings remain unchanged,
including `Ctrl+\` for the previous window/pane.

Inside a Herdr pane, `lua/plugins/vim-tmux-navigator.lua` asks
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

- **Format on save** via `conform.nvim` (`lsp_format = 'fallback'`,
  `timeout_ms = 2000`); disabled for `c`/`cpp`.
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
- `lazy-lock.json` pins plugin versions — commit it when you intentionally
  update plugins (`:Lazy update`).
