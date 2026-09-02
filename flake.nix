{
  # Third-party tooling this machine needs, declared in one place. Replaces the
  # per-tool installers that used to live in tools/ -- see tools/README.md for
  # what is still a script and why.
  #
  # Install:  nix profile install ~/.dots
  # Update:   nix flake update --flake ~/.dots && nix profile upgrade dots-tools
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
          delta
          # Canonical `fd` name: apt ships it as `fdfind` (Debian renames it to
          # avoid a clash), which telescope and fzf do not auto-detect.
          fd
          fzf
          glow
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
          # pnpm_10, not pnpm: the unversioned attr is 11.x, and these were on
          # 10.33.0 under nvm. Same major keeps existing lockfiles predictable.
          pnpm_10
          yarn # 1.22.22, identical to what nvm had
          # Formatters and linters nvim shells out to, and that `just check`
          # also runs. Previously split across apt and mason for no reason --
          # shfmt and shellcheck were installed by both.
          eslint_d
          prettierd
          shellcheck
          shfmt
          stylua
          # `rg` for telescope and grep; apt's copy stays but is shadowed.
          ripgrep
          tealdeer # ships the `tldr` binary
          # NOT tmux-sessionizer: nixpkgs packages jrmoulton's Rust rewrite
          # (binary `tms`), not ThePrimeagen's shell script that this repo's
          # tmux.conf and keybinds.sh call by name. Stays a script.
          #
          # NOT wrangler: tools/install-cloudflare.sh installs it as a pair with
          # `cf`, which is not in nixpkgs. Taking only half the pair put two
          # wranglers on PATH, with the npm one shadowing this.
        ];
      };
    };
}
