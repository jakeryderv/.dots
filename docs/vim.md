# vim

Personal classic Vim configuration. This is intentionally lightweight and
separate from the plugin-heavy Lua configuration in [`nvim`](nvim.md).

## Layout

The tracked entry point is `.vim/vimrc`, which Vim loads from
`~/.vim/vimrc`. Keep `~/.vim` as a real directory so generated state and local
runtime files can coexist without being written into this repository.

```text
~/.vim/                 # real directory
├── vimrc -> ~/.dots/home/vim/vimrc
└── undo/               # generated locally by Vim
```

## Activate

```bash
just apply vim
```

This is a `tree` row, so `~/.vim/` stays a real directory holding one symlink
per tracked file. Vim's own scratch files (`undo/`, `.netrwhist`, viminfo) sit
beside them instead of landing in the repo.

## Included behavior

- Relative and absolute line numbers, mouse support, visible whitespace, and
  four-space indentation (`softtabstop=-1`, so `<Tab>`/`<BS>` move a whole
  step). A `FileType` autocmd drops to two spaces for Lua, the web filetypes,
  and Markdown, matching the [`nvim`](nvim.md) config.
- **No EditorConfig support.** Vim cannot read `.editorconfig`, so the two-space
  list above hardcodes the convention rather than reading a project's file — a
  repository with different rules is not honoured here, though Neovim does
  honour it. See [`editorconfig`](editorconfig.md). Adding
  `editorconfig-vim` would close the gap at the cost of this config's
  zero-plugin property; the tradeoff was judged not worth it.
- Smart-case incremental search, persistent undo, true color, and predictable
  split placement.
- **Local carbonfox colorscheme**, `.vim/colors/carbonfox.vim` — hand-written
  to match what `nightfox.nvim` renders in [`nvim`](nvim.md), so the
  two editors agree. Still zero plugins; it's just a file in `~/.vim/colors/`.
  Without it Vim uses its own defaults, which are unrelated to carbonfox (blue
  comments, yellow keywords) and come from two places: compiled into the binary
  for UI groups, and `$VIMRUNTIME/syntax/syncolor.vim` for syntax groups.
  `Normal` is deliberately left cleared so the terminal background — and
  Ghostty's background image — still shows through. `cterm` values use
  carbonfox's ANSI slot numbers rather than 256-colour approximations, since
  the terminal palette is itself carbonfox.
- `Ctrl-h/j/k/l` and `Ctrl-\` navigation across Vim splits and tmux panes,
  implemented directly without a Vim plugin.

## Requirements

- Vim with `+persistent_undo` and `+termguicolors` (the repository's target
  Vim 9.1 build provides both).
- tmux is optional; navigation falls back to Vim splits outside tmux.

