# nvim

Personal Neovim config (Lua, `lazy.nvim`). Deployed to `~/.config/nvim/`.

## Requirements

- **Neovim ≥ 0.12** — the config uses modern APIs (`vim.lsp.config()` /
  `vim.lsp.enable()`, `vim.hl.on_yank()`, `vim.o.winborder`,
  `client:supports_method()`). It has a runtime fallback for `nvim-0.11`, but is
  developed and tested against 0.12. Installed from [`flake.nix`](../flake.nix).
- **git**, **curl** — plugin + tool fetching.
- A **Nerd Font** (the repo ships `0xProto Nerd Font`; see root README for
  `fc-cache`/`fc-match`). Icons assume `vim.g.have_nerd_font`.

## First-run order

Plugins install on first launch via `lazy.nvim`; Mason then installs the
language servers. Install the [distro prerequisites](../README.md#setup-on-a-new-machine)
and the Nix profile first: `tree-sitter` comes from the flake, while the C
compiler and make come from the distro's `build-essential`. Recommended
sequence on a fresh machine:

1. `nvim` — let `lazy.nvim` finish installing plugins, then quit.
2. `nvim` again — Mason auto-installs the LSP servers listed below. Wait for
   `:Mason` / fidget to report done. Restart. (Formatters, linters and
   `tree-sitter` are not Mason's; they come from
   [`flake.nix`](../flake.nix).)
3. `:TSUpdate` — build/refresh Treesitter parsers.

## Tooling ownership

Split deliberately: Mason owns the language servers, which churn fastest and
benefit from its auto-install; the flake owns everything else, which is stable
and is also run by `dots check`, so pinning it keeps the editor
and CI on one version.

| Tool | Owner | Notes |
|------|-------|-------|
| LSP servers: `lua_ls`, `bashls`, `pyright`, `html`, `cssls`, `emmet_language_server`, `vtsls` | Mason (`mason-lspconfig`) | auto-installed |
| Formatters: `stylua`, `shfmt`, `prettierd` | [`flake.nix`](../flake.nix) | same binaries `dots check` uses |
| Linters: `shellcheck`, `eslint_d` | [`flake.nix`](../flake.nix) | `.shellcheckrc` is read by both |
| `tree-sitter` CLI | [`flake.nix`](../flake.nix) | builds every parser; was Mason's, but Mason's remit here is language servers |
| **`ruff`** (Python format + lint) | [`flake.nix`](../flake.nix) | was a `uv tool` install; moved so all six formatters/linters share one owner |

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
  [`flake.nix`](../flake.nix).

Everything else a plugin shells out to is already declared in
[`flake.nix`](../flake.nix) and needs no separate step: `rg` and `fd`
(telescope auto-detects both -- the reason `fd` is in the flake at all),
`lazygit`, `tmux` for vim-tmux-navigator, and `git` for lazy.nvim's clones.

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
