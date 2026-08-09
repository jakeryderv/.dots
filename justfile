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
    @bash _helpers/check-repo.sh

# Health checks against the live filesystem and shell wiring.
doctor:
    @bash _dots/bin/doctor.sh

# Report which expected tools are installed.
deps:
    @bash _dots/bin/deps.sh

# Documentation coverage only.
readmes:
    @bash _helpers/verify-readmes.sh

# Run an installer from _helpers, e.g. `just install delta`.
install TOOL:
    @bash _helpers/install-{{ TOOL }}.sh
