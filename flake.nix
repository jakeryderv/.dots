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

      # image.nvim's `magick` luarock calls ffi.load("MagickWand"), i.e. dlopen
      # of a plain "libMagickWand.so". Two things make that fail here: nixpkgs
      # ships only versioned names, and a Nix binary's dynamic linker never
      # searches /usr/lib, so the apt-installed ImageMagick is invisible to it.
      # Provide the unversioned names the rock actually looks for. Globbed
      # rather than hardcoded so an ImageMagick major bump does not break it.
      magickCompat = pkgs.runCommand "magick-compat" { } ''
        mkdir -p $out/lib
        ln -s "$(echo ${pkgs.imagemagick}/lib/libMagickWand-*.so)" $out/lib/libMagickWand.so
        ln -s "$(echo ${pkgs.imagemagick}/lib/libMagickCore-*.so)" $out/lib/libMagickCore.so
      '';

      # Wrapped rather than adding imagemagick to paths: that would put v7's
      # `magick`/`convert` ahead of the system v6 CLI on PATH, which nothing
      # here asked for. Only nvim needs to see these libraries.
      neovim-magick = pkgs.symlinkJoin {
        name = "neovim-magick";
        paths = [ pkgs.neovim ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/nvim \
            --prefix LD_LIBRARY_PATH : "${magickCompat}/lib:${pkgs.imagemagick}/lib"
        '';
      };
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
          neovim-magick # neovim + ImageMagick libs for image.nvim
          tealdeer # ships the `tldr` binary
          # NOT tmux-sessionizer: nixpkgs packages jrmoulton's Rust rewrite
          # (binary `tms`), not ThePrimeagen's shell script that this repo's
          # tmux.conf and keybinds.sh call by name. Stays a script.
          wrangler
        ];
      };
    };
}
