# docs/

Per-package documentation, one file per package: `docs/<pkg>.md`.

These live here rather than beside the config they describe because source
directories under [`config/`](../config/README.md), `home/`, `data/`, and `bin/`
contain **only deployable content** — a `README.md` inside `config/alacritty/`
would be enumerated by `git ls-files` and deployed to
`~/.config/alacritty/README.md`.

Keeping docs out of the source trees is what lets the deployer run with zero
exclusion rules.

Each file should cover: what the tool is, where it deploys, how to activate it
beyond linking, and any external dependencies.

| Doc | Source | Deploys to |
| --- | --- | --- |
| [`alacritty.md`](alacritty.md) | `config/alacritty` | `~/.config/alacritty/` |
| [`bat.md`](bat.md) | `config/bat` | `~/.config/bat/` |
| [`claude.md`](claude.md) | `home/claude` | `~/.claude/` |
| [`direnv.md`](direnv.md) | `config/direnv` | `~/.config/direnv/` |
| [`editorconfig.md`](editorconfig.md) | `home/editorconfig` | `~/.editorconfig` |
| [`fonts.md`](fonts.md) | `data/fonts` | `~/.local/share/fonts/` |
| [`ghostty.md`](ghostty.md) | `config/ghostty` | `~/.config/ghostty/` |
| [`git.md`](git.md) | `home/gitconfig` | `~/.gitconfig` |
| [`kanata.md`](kanata.md) | `config/kanata`, `config/systemd/user` | `~/.config/kanata/`, `~/.config/systemd/user/` |
| [`kitty.md`](kitty.md) | `config/kitty` | `~/.config/kitty/` |
| [`nvim.md`](nvim.md) | `config/nvim` | `~/.config/nvim/` |
| [`opencode.md`](opencode.md) | `config/opencode` | `~/.config/opencode/` |
| [`openspec.md`](openspec.md) | `config/openspec` | `~/.config/openspec/` |
| [`qutebrowser.md`](qutebrowser.md) | `config/qutebrowser` | `~/.config/qutebrowser/` |
| [`scripts.md`](scripts.md) | `bin`, `data/bash-completion/completions` | `~/.local/bin/`, completions |
| [`starship.md`](starship.md) | `config/starship.toml` | `~/.config/starship.toml` |
| [`tealdeer.md`](tealdeer.md) | `config/tealdeer` | `~/.config/tealdeer/` |
| [`tmux.md`](tmux.md) | `home/tmux.conf` | `~/.tmux.conf` |
| [`vim.md`](vim.md) | `home/vim` | `~/.vim/` |
| [`wezterm.md`](wezterm.md) | `config/wezterm` | `~/.config/wezterm/` |
