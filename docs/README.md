# docs/

Per-package documentation, one file per package: `docs/<pkg>.md`.

These live here rather than beside the config they describe because source
directories under [`config/`](../pkgs/README.md), `home/`, `data/`, and `bin/`
contain **only deployable content** — a `README.md` inside `pkgs/alacritty/`
would be enumerated by `git ls-files` and deployed to
`~/.config/alacritty/README.md`.

Keeping docs out of the source trees is what lets the deployer run with zero
exclusion rules.

Each file should cover: what the tool is, where it deploys, how to activate it
beyond linking, and any external dependencies.

One file does double duty: [`nix.md`](nix.md) is the package doc for
`pkgs/nix` (the flakes opt-in) and also documents [`flake.nix`](../flake.nix),
which provisions software rather than deploying config — the other half of how
this repo is applied.

| Doc | Source | Deploys to |
| --- | --- | --- |
| [`agent-skills.md`](agent-skills.md) | `pkgs/agent-skills/project-practices` | `~/.agents/skills/`, `~/.claude/skills/` |
| [`alacritty.md`](alacritty.md) | `pkgs/alacritty` | `~/.config/alacritty/` |
| [`bat.md`](bat.md) | `pkgs/bat` | `~/.config/bat/` |
| [`claude.md`](claude.md) | `pkgs/claude` | `~/.claude/` |
| [`direnv.md`](direnv.md) | `pkgs/direnv` | `~/.config/direnv/` |
| [`editorconfig.md`](editorconfig.md) | `pkgs/editorconfig/editorconfig` | `~/.editorconfig` |
| [`fonts.md`](fonts.md) | `pkgs/fonts` | `~/.local/share/fonts/` |
| [`ghostty.md`](ghostty.md) | `pkgs/ghostty` | `~/.config/ghostty/` |
| [`git.md`](git.md) | `pkgs/git/gitconfig` | `~/.gitconfig` |
| [`herdr.md`](herdr.md) | `pkgs/herdr` | `~/.config/herdr/` |
| [`kanata.md`](kanata.md) | `pkgs/kanata`, `pkgs/kanata` | `~/.config/kanata/`, `~/.config/systemd/user/` |
| [`kitty.md`](kitty.md) | `pkgs/kitty` | `~/.config/kitty/` |
| [`nix.md`](nix.md) | `pkgs/nix`; `flake.nix`, `flake.lock` | `~/.config/nix/`; the flake via `nix profile`, not a link |
| [`nvim.md`](nvim.md) | `pkgs/nvim` | `~/.config/nvim/` |
| [`scripts.md`](scripts.md) | `bin` | `~/.local/bin/` |
| [`starship.md`](starship.md) | `pkgs/starship/starship.toml` | `~/.config/starship.toml` |
| [`tealdeer.md`](tealdeer.md) | `pkgs/tealdeer` | `~/.config/tealdeer/` |
| [`tmux.md`](tmux.md) | `pkgs/tmux/tmux.conf` | `~/.tmux.conf` |
| [`vim.md`](vim.md) | `pkgs/vim` | `~/.vim/` |
| [`wezterm.md`](wezterm.md) | `pkgs/wezterm` | `~/.config/wezterm/` |
