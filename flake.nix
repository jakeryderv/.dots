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
          fzf
          glow
          # Default build is compiled without `cmd` support, which is the
          # property the old installer went out of its way to preserve. Do not
          # swap this for kanata-with-cmd.
          kanata
          lazygit
          neovim
          tealdeer # ships the `tldr` binary
          # NOT tmux-sessionizer: nixpkgs packages jrmoulton's Rust rewrite
          # (binary `tms`), not ThePrimeagen's shell script that this repo's
          # tmux.conf and keybinds.sh call by name. Stays a script.
          wrangler
        ];
      };
    };
}
