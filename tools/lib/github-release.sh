# shellcheck shell=bash
# github-release.sh -- shared plumbing for installers that download GitHub
# release assets. Sourced by tools/install-*.sh, never executed; the shell
# directive above (instead of a shebang) is what keeps it inside
# check-repo.sh's lint surface.
#
# Call order in an installer:
#
#   gh_parse_force_flag "$@"            # sets FORCE; implements -h/--help
#   gh_require_linux_x86_64
#   gh_require_cmds tar dpkg            # curl jq sha256sum awk are implied
#   gh_resolve_latest owner/repo        # sets RELEASE_JSON, GH_TAG, GH_VERSION
#   gh_fetch_asset NAME DEST            # select by exact name, download, verify
#   gh_fetch_asset_matching PRED DEST   # ...or by a jq predicate on .name
#
# Errors are fatal: helpers print to stderr and exit, which terminates the
# sourcing installer. The tests exercise failure paths in subshells for this
# reason.

_gh_die() {
    echo "Error: $*" >&2
    exit 1
}

# Standard single-flag CLI for re-runnable installers. Sets FORCE=1 when
# --force is passed so the caller can override its up-to-date short-circuit.
# shellcheck disable=SC2034 # FORCE is consumed by the sourcing installer
gh_parse_force_flag() {
    FORCE=0
    case "${1-}" in
    "") ;;
    -f | --force) FORCE=1 ;;
    -h | --help)
        echo "usage: ${0##*/} [--force]"
        echo "  --force  reinstall even when already at the latest version"
        exit 0
        ;;
    *)
        echo "Error: unknown argument '$1' (try --help)" >&2
        exit 2
        ;;
    esac
}

gh_require_linux_x86_64() {
    [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] ||
        _gh_die "this helper supports Linux x86_64 only"
}

# The commands every release download needs, plus whatever the caller adds.
gh_require_cmds() {
    local cmd
    for cmd in curl jq sha256sum awk "$@"; do
        command -v "$cmd" >/dev/null 2>&1 ||
            _gh_die "required command '$cmd' was not found"
    done
}

# Resolve the latest release of owner/repo. Sets, for the caller:
#   RELEASE_JSON  the release object, for further jq queries
#   GH_TAG        the tag exactly as published (not every repo v-prefixes)
#   GH_VERSION    the tag with any leading "v" stripped
# shellcheck disable=SC2034 # set for the sourcing installer
gh_resolve_latest() {
    local repo="$1"
    RELEASE_JSON=$(curl -fsSL --retry 3 "https://api.github.com/repos/$repo/releases/latest") ||
        _gh_die "failed to query the release API for $repo"
    GH_TAG=$(printf '%s' "$RELEASE_JSON" | jq -er '.tag_name | select(type == "string" and length > 0)') ||
        _gh_die "the release API for $repo did not return a valid tag"
    GH_VERSION="${GH_TAG#v}"
}

# Select exactly one asset whose .name satisfies the jq predicate, download it
# to DEST, and check it against the SHA-256 digest GitHub publishes alongside
# it -- so a corrupted or substituted file never reaches the install step.
gh_fetch_asset_matching() {
    local predicate="$1" dest="$2"
    local asset name url digest expected actual
    asset=$(printf '%s' "$RELEASE_JSON" | jq -cer "
        [.assets[] | select(.name | $predicate)]
        | if length == 1 then .[0] else error(\"expected exactly one matching asset, found \(length)\") end
    ") || _gh_die "could not select exactly one release asset (predicate: $predicate)"
    name=$(printf '%s' "$asset" | jq -er '.name') || _gh_die "release asset has no name"
    url=$(printf '%s' "$asset" | jq -er '.browser_download_url') || _gh_die "no download URL for $name"
    digest=$(printf '%s' "$asset" | jq -er '.digest') || _gh_die "no digest published for $name"
    [[ "$digest" =~ ^sha256:([0-9a-fA-F]{64})$ ]] || _gh_die "invalid SHA-256 digest for $name"
    expected="${BASH_REMATCH[1],,}"

    curl -fL --retry 3 -o "$dest" "$url" || _gh_die "failed to download $name"

    actual=$(sha256sum "$dest" | awk '{print $1}') || _gh_die "failed to hash $dest"
    [[ "$actual" == "$expected" ]] || _gh_die "SHA-256 verification failed for $name"
    echo "Verified SHA-256: $actual ($name)"
}

# The common case: select the asset by its exact name.
gh_fetch_asset() {
    local name="$1" dest="$2"
    gh_fetch_asset_matching ". == $(printf '%s' "$name" | jq -R .)" "$dest"
}

# True when INSTALLED is non-empty and at least LATEST. dpkg does the
# comparison so upstream's scheme is honored rather than a string compare,
# which would call 0.9.0 newer than 0.19.2. Callers must list dpkg in
# gh_require_cmds.
gh_up_to_date() {
    local installed="$1" latest="$2"
    [[ -n "$installed" ]] && dpkg --compare-versions "$installed" ge "$latest"
}
