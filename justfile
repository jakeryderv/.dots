# ~/.dots task runner.
#
# Linking is driven by ./manifest -- see the header there for the MODE column.
# Run these from anywhere via the `dots` wrapper in bin/, which is deployed to
# ~/.local/bin and simply points `just` back at this file.

_default:
    @just --list --unsorted

# Show link state for every manifest row (or only PKGS).
status *PKGS:
    @_dots/bin/link.sh status {{ PKGS }}

# Preview link changes without touching the filesystem.
plan *PKGS:
    @_dots/bin/link.sh plan {{ PKGS }}

# Create or repoint symlinks.
apply *PKGS:
    @_dots/bin/link.sh apply {{ PKGS }}

# Remove symlinks that resolve into this repo.
unlink *PKGS:
    @_dots/bin/link.sh unlink {{ PKGS }}

# Show content differences for targets that drifted from their source.
diff *PKGS:
    @_dots/bin/link.sh diff {{ PKGS }}

# List the package names the manifest knows about.
packages:
    @awk '!/^#/ && NF {print $1}' manifest | sort -u

# Portable repository validation (what CI runs).
check:
    @bash _dots/checks/check-repo.sh

# Health checks against the live filesystem and shell wiring.
doctor:
    @bash _dots/bin/doctor.sh

# Report which expected tools are installed.
deps:
    @bash _dots/bin/deps.sh

# Documentation coverage only.
readmes:
    @bash _dots/checks/verify-readmes.sh

# List the installers available to `just install`.
tools:
    @ls tools/install-*.sh | sed 's|tools/install-||; s|\.sh$||'

# Run an installer from tools, e.g. `just install delta`.
install TOOL:
    @bash tools/install-{{ TOOL }}.sh

# Install the latest stable Neovim from the official release build.
update-nvim:
    @bash tools/update-nvim.sh
