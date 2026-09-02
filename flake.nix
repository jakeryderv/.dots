{
  # Third-party tooling this machine needs, declared in one place. Replaces the
  # per-tool installers that used to live in tools/ -- see docs/nix.md for how
  # this half of the repo works, and tools/README.md for what is still a script.
  #
  # Install and update commands are in docs/nix.md, and only there.
  #
  # flake.lock is committed: it is what makes a second machine resolve the same
  # versions, the same way the manifest makes it resolve the same symlinks.
  description = "Toolchain for jake's dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      # One list, built per architecture. Only x86_64 has ever been installed
      # from this; aarch64 is here so an ARM machine does not fail at
      # `nix profile add` with a missing attribute, but nothing in the list has
      # been exercised there. genAttrs is all the fan-out needed, so no
      # flake-utils input.
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forEachSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.buildEnv {
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
          # apt's git is 2.43 (Ubuntu 24.04). /usr/bin/git stays -- docker-ce,
          # git-lfs and dpkg tooling depend on it -- and is shadowed. It is the
          # one apt copy of a flake tool left, besides fd-find (pop-launcher).
          git
          glow
          # This repo's own task runner, so `just apply` works on a machine
          # where the only bootstrap step was installing Nix. apt has 1.42.
          just
          # Default build is compiled without `cmd` support, which is the
          # property the old installer went out of its way to preserve. Do not
          # swap this for kanata-with-cmd.
          kanata
          # The other keyboard tool: firmware, where kanata is remapping. Was a
          # `uv tool` install needing `--python 3.14 --with pip`; nixpkgs owns
          # those dependencies, so the spec that made it worth scripting
          # disappears here. The toolchains it downloads live in
          # ~/.local/share/qmk, outside the store.
          qmk
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
          # `rg` for telescope and grep.
          ripgrep
          # nvim-treesitter compiles every parser with this. It was a mason
          # package, but mason's boundary here is language servers, which churn
          # -- a build tool pinned at a minimum of 0.26.1 is not that. Being on
          # the shell PATH too is the point when a parser build needs debugging.
          tree-sitter
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
          # --- The other toolchain managers, on the same terms as uv: the
          # manager is machine-level, what it manages lives in $HOME and is
          # per-project. Their self-updaters cannot write to the store, so
          # updating any of them means updating the flake. See docs/nix.md.
          #
          # rustup, not rustc/cargo: toolchains stay in ~/.rustup, where
          # rust-toolchain.toml picks one per project. `rustup self update`
          # is disabled in this build, like uv's. The proxies rustup-init
          # had put in ~/.cargo/bin were deleted; that directory stays on
          # PATH, after this profile, for `cargo install` output only.
          rustup
          # Base Go. GOTOOLCHAIN=auto fetches whatever a go.mod asks for
          # into the module cache, so one global version is right. Replaces
          # a webi tarball in ~/.local/opt/go; ~/go/bin stays on PATH,
          # after this profile, for `go install` output.
          go
          # Runtime plus package manager, the node case again. Replaces the
          # curl installer's ~/.bun/bin/bun. nixpkgs trails bun's release
          # cadence by about a minor (1.3.13 against the 1.4.0 it replaced)
          # -- taken anyway, for one owner across all four managers.
          bun
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
        });
    };
}
