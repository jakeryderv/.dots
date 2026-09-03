{
  # Third-party tooling this machine needs, declared in one place. Replaces the
  # per-tool installers that used to live in tools/ -- see docs/nix.md for how
  # this half of the repo works, and tools/README.md for what is still a script.
  #
  # Install and update commands are in docs/nix.md, and only there.
  #
  # flake.lock is committed: it is what makes a second machine resolve the same
  # versions, the same way dots.toml makes it resolve the same symlinks.
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
      tools = import ./nix/tools.nix;
    in
    {
      # The package list as a function, for a NixOS or home-manager config
      # that wants the same tools without going through the profile.
      lib.tools = tools;

      packages = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dots = import ./nix/dots.nix { inherit pkgs; };
        in
        {
          inherit dots;
          # What `nix profile add ~/.dots` installs: the toolchain plus dots.
          default = pkgs.buildEnv {
            name = "dots-tools";
            paths = tools pkgs ++ [ dots ];
          };
        });
    };
}
