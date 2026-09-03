# docs/

Per-package documentation, one file per package: `docs/<pkg>.md`.

These live here rather than beside the config they describe because package
directories under [`config/`](../config/README.md) contain **only deployable
content** — a `README.md` inside `config/alacritty/` would be enumerated by
`git ls-files` and deployed to `~/.config/alacritty/README.md`. `dots validate`
refuses one.

Keeping docs out of the source trees is what lets the deployer run with zero
exclusion rules.

Each file should cover: what the tool is, where it deploys, how to activate it
beyond linking, and any external dependencies.

One file does double duty: [`nix.md`](nix.md) is the package doc for
`config/nix` (the flakes opt-in) and also documents [`flake.nix`](../flake.nix),
which provisions software rather than deploying config — the other half of how
this repo is applied.

| Doc | Source | Deploys to |
| --- | --- | --- |
| [`agent-skills.md`](agent-skills.md) | `config/agent-skills/project-practices` | `~/.agents/skills/`, `~/.claude/skills/` |
| [`alacritty.md`](alacritty.md) | `config/alacritty` | `~/.config/alacritty/` |
| [`bash.md`](bash.md) | `config/bash/bashrc` | `~/.bashrc` |
| [`bat.md`](bat.md) | `config/bat` | `~/.config/bat/` |
| [`claude.md`](claude.md) | `config/claude` | `~/.claude/` |
| [`direnv.md`](direnv.md) | `config/direnv` | `~/.config/direnv/` |
| [`editorconfig.md`](editorconfig.md) | `config/editorconfig/editorconfig` | `~/.editorconfig` |
| [`fonts.md`](fonts.md) | `config/fonts` | `~/.local/share/fonts/` |
| [`ghostty.md`](ghostty.md) | `config/ghostty` | `~/.config/ghostty/` |
| [`git.md`](git.md) | `config/git/gitconfig` | `~/.gitconfig` |
| [`herdr.md`](herdr.md) | `config/herdr` | `~/.config/herdr/` |
| [`kanata.md`](kanata.md) | `config/kanata`, `config/kanata` | `~/.config/kanata/`, `~/.config/systemd/user/` |
| [`kitty.md`](kitty.md) | `config/kitty` | `~/.config/kitty/` |
| [`nix.md`](nix.md) | `config/nix`; `flake.nix`, `flake.lock` | `~/.config/nix/`; the flake via `nix profile`, not a link |
| [`nvim.md`](nvim.md) | `config/nvim` | `~/.config/nvim/` |
| [`scripts.md`](scripts.md) | `bin` | `~/.local/bin/` |
| [`shell.md`](shell.md) | `config/shell` | `~/.config/shell/` |
| [`starship.md`](starship.md) | `config/starship/starship.toml` | `~/.config/starship.toml` |
| [`tealdeer.md`](tealdeer.md) | `config/tealdeer` | `~/.config/tealdeer/` |
| [`tmux.md`](tmux.md) | `config/tmux/tmux.conf` | `~/.tmux.conf` |
| [`vim.md`](vim.md) | `config/vim` | `~/.vim/` |
| [`wezterm.md`](wezterm.md) | `config/wezterm` | `~/.config/wezterm/` |
