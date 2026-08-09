# ~/.dots task runner.
#
# Linking is driven by ./manifest -- see the header there for the MODE column
# and the phase-1/phase-2 migration split.

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

# List the package names the manifest knows about.
packages:
    @awk '!/^#/ && NF {print $1}' manifest | sort -u

# Portable repository validation (what CI runs).
check:
    @bash _helpers/check-repo.sh

# Repo health checks against the live filesystem and shell wiring.
doctor:
    @dots doctor

# Run an installer from _helpers, e.g. `just install delta`.
install TOOL:
    @bash _helpers/install-{{ TOOL }}.sh
