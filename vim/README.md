# vim

Personal classic Vim configuration. This is intentionally lightweight and
separate from the plugin-heavy Lua configuration in [`nvim`](../nvim/README.md).

## Layout

The tracked entry point is `.vim/vimrc`, which Vim loads from
`~/.vim/vimrc`. Keep `~/.vim` as a real directory so generated state and local
runtime files can coexist without being written into this repository.

```text
~/.vim/                 # real directory
├── vimrc -> ~/.dots/vim/.vim/vimrc
└── undo/               # generated locally by Vim
```

## Activate

Use the package-specific `--no-folding` option when stowing or restowing:

```bash
cd ~/.dots
dots stow --no-folding --apply vim
dots restow --no-folding --apply vim
```

This makes Stow create real target directories and link only the files tracked
by the package.

## Included behavior

- Relative and absolute line numbers, mouse support, visible whitespace, and
  four-space indentation (`softtabstop=-1`, so `<Tab>`/`<BS>` move a whole
  step). A `FileType` autocmd drops to two spaces for Lua, the web filetypes,
  and Markdown, matching the [`nvim`](../nvim/README.md) config.
- **No EditorConfig support.** Vim cannot read `.editorconfig`, so the two-space
  list above hardcodes the convention rather than reading a project's file — a
  repository with different rules is not honoured here, though Neovim does
  honour it. See [`editorconfig`](../editorconfig/README.md). Adding
  `editorconfig-vim` would close the gap at the cost of this config's
  zero-plugin property; the tradeoff was judged not worth it.
- Smart-case incremental search, persistent undo, true color, and predictable
  split placement.
- `Ctrl-h/j/k/l` and `Ctrl-\` navigation across Vim splits and tmux panes,
  implemented directly without a Vim plugin.

## Requirements

- Vim with `+persistent_undo` and `+termguicolors` (the repository's target
  Vim 9.1 build provides both).
- tmux is optional; navigation falls back to Vim splits outside tmux.

