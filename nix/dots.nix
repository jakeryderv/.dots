# The `dots` command as a package, so `nix profile add ~/.dots` puts it on
# PATH before a single symlink exists -- that is what removes the bootstrap
# step of running dots.py by hand once.
#
# A wrapper, not a copy: it execs the live dots.py in the checkout with a
# pinned interpreter. Copying the script into the store would mean every edit
# needs `nix profile upgrade` before it takes effect, which is the wrong shape
# for a tool edited in place. The interpreter is the store's python3, so
# nothing on PATH is needed and python3 is not in the profile for this.
{ pkgs }:
pkgs.writeShellApplication {
  name = "dots";
  text = ''
    repo="''${DOTS_REPO:-$HOME/.dots}"
    if [[ ! -f "$repo/dots.py" ]]; then
      echo "error: no dots.py under $repo (set DOTS_REPO to override)" >&2
      exit 1
    fi
    exec ${pkgs.python3}/bin/python3 "$repo/dots.py" --repo "$repo" "$@"
  '';
}
