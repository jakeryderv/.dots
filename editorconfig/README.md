# editorconfig

Machine-wide [EditorConfig](https://editorconfig.org/) fallback. Stowed to
`~/.editorconfig`.

## Why

Indentation rules are read by more than the editor. Neovim has built-in
EditorConfig support, and so do the formatters `conform.nvim` runs — `stylua`,
`prettierd`, and `shfmt`. Putting the rules in EditorConfig instead of per-tool
config means the editor and the formatters cannot disagree.

Without a fallback, that only holds inside projects that ship a config. A stray
`~/tmp/foo.sh` gets each tool's own default instead — notably **shfmt formats
shell with tabs**, silently undoing `expandtab` on save.

## Precedence

This file deliberately omits `root = true`. EditorConfig walks up the directory
tree from the file being edited and stops at the first config marked root, so:

```text
project/.editorconfig (root = true)   ->  wins; this file is never consulted
project with no config               ->  falls through to ~/.editorconfig
```

`~/.dots/.editorconfig` **is** marked `root = true` and governs this repository.
The two files carry the same rules; keep them in sync when either changes.

Within Neovim, EditorConfig is applied after ftplugins and after the
`web-indent` autocmd in `nvim/.config/nvim/lua/autocmds.lua`, so it overrides
them. That is the intended ordering.

## Rules

| Pattern | Indent |
| --- | --- |
| `*` | 4 spaces |
| `*.lua` | 2 spaces |
| web filetypes, `*.md` | 2 spaces |
| `Makefile` | tabs |

`trim_trailing_whitespace` is on everywhere except Markdown, where two trailing
spaces are a hard line break.

## Activate

```bash
cd ~/.dots
dots stow --apply editorconfig
```

## Caveats

- **`stylua` ignores EditorConfig when a `stylua.toml` is present** in the
  file's directory. `nvim/.config/nvim/.stylua.toml` therefore governs the
  Neovim config; it also says 2, so the two agree.
- **`shfmt` ignores EditorConfig as soon as formatting flags are passed.** Do
  not add `prepend_args` to the `shfmt` entry in `conform.lua` — set the
  corresponding EditorConfig key instead.
- `switch_case_indent` is left unset on purpose; see the comment in
  `.editorconfig`.
