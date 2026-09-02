{
  # Third-party tooling this machine needs, declared in one place. Replaces the
  # per-tool installers that used to live in tools/ -- see docs/nix.md for how
  # this half of the repo works, and tools/README.md for what is still a script.
  #
  # Install:  nix profile add ~/.dots
  # Update:   nix flake update --flake ~/.dots, then `nix profile upgrade`
  #           addressed by the entry's flake URL -- NOT `dots-tools`, which
  #           matches no entry and warns instead of upgrading. Exact command
  #           in docs/nix.md.
  #
  # flake.lock is committed: it is what makes a second machine resolve the same
  # versions, the same way the manifest makes it resolve the same symlinks.
  description = "Toolchain for jake's dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      # Single-platform on purpose: tools/README.md already scopes this repo to
      # Linux x86_64, so a flake-utils dependency would buy nothing.
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "dots-tools";
        paths = with pkgs; [
          ast-grep
          # Canonical `bat` name: apt ships it as `batcat` for the same reason
          # it renames fd. The guarded alias in shell/aliases.sh becomes a
          # no-op once the real name is on PATH.
          bat
          delta
          # The host for nix-direnv, which was already here. apt's is 2.32.1
          # against 2.37.1 -- plugin and host were under different managers,
          # the same split that sends wrangler to npm alongside `cf`.
          direnv
          # Canonical `fd` name: apt ships it as `fdfind` (Debian renames it to
          # avoid a clash), which telescope and fzf do not auto-detect.
          fd
          fzf
          # Replaces a hand-added cli.github.com apt source and its GPG key,
          # which nothing in this repo managed. ~/.gitconfig.local's credential
          # helper must call bare `gh`, not /usr/bin/gh, or it silently pins to
          # the apt copy.
          gh
          # apt's git is 2.43 (Ubuntu 24.04). /usr/bin/git stays -- system
          # packages depend on it -- and is shadowed, same as ripgrep.
          git
          glow
          # This repo's own task runner, so `just apply` works on a machine
          # where the only bootstrap step was installing Nix. apt has 1.42.
          just
          # Default build is compiled without `cmd` support, which is the
          # property the old installer went out of its way to preserve. Do not
          # swap this for kanata-with-cmd.
          kanata
          lazygit
          neovim
          # Replaces nvm. npm ships with it; global installs need a writable
          # prefix (~/.npm-global) because the store is read-only -- see
          # shell/exports.sh.
          nodejs
          # Caches `use flake` evaluations for direnv and keeps the resulting
          # store paths alive as GC roots; without it every cd re-evaluates.
          # Hooked up in config/direnv/direnvrc; direnv itself is above.
          nix-direnv
          # pnpm_10, not pnpm: the unversioned attr is 11.x, and these were on
          # 10.33.0 under nvm. Same major keeps existing lockfiles predictable.
          pnpm_10
          yarn # 1.22.22, identical to what nvm had
          # Formatters and linters nvim shells out to, and that `just check`
          # also runs. Previously split across apt and mason for no reason --
          # shfmt and shellcheck were installed by both.
          eslint_d
          prettierd
          # ruff joins them rather than staying a `uv tool` install: uv owns
          # the per-project layer, and a formatter/linter is the same
          # machine-level category as the five above.
          ruff
          shellcheck
          shfmt
          stylua
          # `rg` for telescope and grep; apt's copy stays but is shadowed.
          ripgrep
          # Was /usr/local/bin/starship, dropped there by starship.rs' curl
          # installer with nothing tracking it. starship.toml was a manifest
          # package whose binary had no provenance at all -- the tmux case.
          starship
          tealdeer # ships the `tldr` binary
          # The project-layer Python manager, itself a machine-level tool. The
          # hand-downloaded ~/.local/bin/uv must go: that directory precedes
          # this one on PATH, so it would shadow this copy. nixpkgs disables
          # `uv self update`, which fails with a clear message rather than
          # fighting the read-only store. uv keeps its interpreters and its
          # PyPI-only tools; see docs/nix.md.
          uv
          # Was a hand-built binary in /usr/local/bin that no package manager
          # and no installer in this repo knew about -- the last unreproducible
          # thing in the daily path. TPM writes plugins to ~/.tmux/plugins at
          # runtime, outside the store, so nothing here needs a wrapper.
          tmux
          # NOT tmux-sessionizer: nixpkgs packages jrmoulton's Rust rewrite
          # (binary `tms`), not ThePrimeagen's shell script that this repo's
          # tmux.conf and keybinds.sh call by name. Vendored into bin/ instead.
          #
          # NOT wrangler: tools/install-npm-globals.sh installs it as a pair
          # with `cf`, which is not in nixpkgs. Taking only half the pair put
          # two wranglers on PATH, with the npm one shadowing this.
        ];
      };
    };
}
