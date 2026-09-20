# One-time Nix removal

The 2026-09-20 migration replaced every package in the local dotfiles Nix
profile and removed the repository's flake, Nix config, shell hook and Nix CI.
Sources and update methods are in [software.md](software.md).

**Completed and verified after a fresh login on 2026-09-20.** The Nix store,
daemon/socket units, build accounts, system shell hooks and user profile state
are removed. All migrated commands resolve outside Nix, Kanata is running
from `~/.local/bin`, and the repository gate passes all 21 tests.

This host used the official multi-user Linux install, with 32 `nixbld` users.
These commands follow the [official uninstall guide](https://nix.dev/manual/nix/stable/installation/uninstall)
and the system files inspected on this machine. They remove the Nix store
and its rollback generations; the migrated tools and project data live elsewhere.

Commands used for this host's cleanup, retained for reference:

```bash
# Authenticate, stop socket activation, then stop the daemon.
sudo -v
sudo systemctl disable --now nix-daemon.socket
sudo systemctl disable --now nix-daemon.service

# Remove only the installer-delimited hook; retain other shell customizations.
# sed keeps a backup alongside each file.
sudo sed -i.pre-nix-removal '/^# Nix$/,/^# End Nix$/d' /etc/bash.bashrc /etc/bashrc /etc/zshrc

sudo rm -f /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf \
  /etc/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.socket
sudo systemctl daemon-reload

# These are the 32 dedicated build accounts found on this host.
for i in $(seq 1 32); do
  sudo userdel "nixbld$i"
done
sudo groupdel nixbld

# Nix installation, root state, and this user's Nix-only state.
sudo rm -rf /nix /etc/nix /root/.nix-channels /root/.nix-defexpr \
  /root/.nix-profile /root/.cache/nix /root/.local/share/nix /root/.local/state/nix
rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.cache/nix \
  ~/.local/share/nix ~/.local/state/nix ~/.config/nix
```

Log out and back in to clear inherited Nix PATH/environment entries from the
graphical session and long-lived terminal processes. In a fresh terminal:

```bash
command -v nix                         # should print nothing
command -v dots kanata qmk             # ~/.local/bin/...
systemctl --user is-active kanata      # active
dots doctor
```

No changes are needed to QMK's compiler downloads, uv/Rust toolchains, npm
globals, Neovim plugins or project environments. Upstream plugin checkouts
may contain their own Nix development examples; those are not runtime
dependencies and were left intact. Historical Nix files remain recoverable
from Git history and the migration records outside this repository.
