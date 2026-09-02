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

Plugins install on first launch via `lazy.nvim`. Tooling installs via Mason,
and Treesitter parsers need `tree-sitter-cli` (installed by Mason) present
*before* they build. Recommended sequence on a fresh machine:

1. `nvim` — let `lazy.nvim` finish installing plugins, then quit.
2. `nvim` again — Mason auto-installs `tree-sitter-cli` and the LSP servers
   below. Wait for `:Mason` / fidget to report done. Restart. (Formatters and
   linters are not Mason's; they come from [`flake.nix`](../flake.nix).)
3. `:TSUpdate` — build/refresh Treesitter parsers now that `tree-sitter-cli`
   exists.

## Tooling ownership

Split deliberately: Mason owns the language servers, which churn fastest and
benefit from its auto-install; the flake owns the formatters and linters, which
are stable and are also run by `just check`, so pinning them keeps the editor
and CI on one version.

| Tool | Owner | Notes |
|------|-------|-------|
| LSP servers: `lua_ls`, `bashls`, `pyright`, `html`, `cssls`, `emmet_language_server`, `vtsls` | Mason (`mason-lspconfig`) | auto-installed |
| Formatters: `stylua`, `shfmt`, `prettierd` | [`flake.nix`](../flake.nix) | same binaries `just check` uses |
| Linters: `shellcheck`, `eslint_d` | [`flake.nix`](../flake.nix) | `.shellcheckrc` is read by both |
| Treesitter CLI | Mason | `tree-sitter-cli`, needed to build parsers |
| **`ruff`** (Python format + lint) | **system** | not via Mason — install with `uv tool install ruff` |

## External (non-Mason) dependencies

These features need system binaries and are **not** installed by Mason:

- **Clipboard** (`clipboard = unnamedplus`) — needs `wl-clipboard` (Wayland) or
  `xclip`/`xsel` (X11). Verify with `:checkhealth provider`.
- **`markdown-preview`** — hard-codes `firefox --new-window` (see
  `markdown-preview.lua`). Needs Firefox on `PATH`, or edit the `browserfunc`.
- **`ruff`** — see table above.

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
