#!/usr/bin/env bash
# Behaviour tests for tools/lib/github-release.sh, run offline: a curl shim on
# PATH serves a fixture release JSON for API queries and copies a fixture
# payload for asset downloads. Failure paths run in subshells because the lib's
# helpers exit the sourcing shell on error -- that is their contract.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

# shellcheck source=tools/lib/github-release.sh
source "$REPO_ROOT/tools/lib/github-release.sh"

# --- fixtures ----------------------------------------------------------------
printf 'payload\n' >"$TEST_ROOT/payload"
GOOD_SHA256="$(sha256sum "$TEST_ROOT/payload" | awk '{print $1}')"
BAD_SHA256="$(printf '0%.0s' {1..64})"

cat >"$TEST_ROOT/release.json" <<EOF
{
  "tag_name": "v1.2.3",
  "assets": [
    {"name": "tool_1.2.3_amd64.deb", "browser_download_url": "https://example.invalid/tool.deb", "digest": "sha256:$GOOD_SHA256"},
    {"name": "tool-x86_64.AppImage", "browser_download_url": "https://example.invalid/tool.AppImage", "digest": "sha256:$GOOD_SHA256"},
    {"name": "tool-bad-digest.tar.gz", "browser_download_url": "https://example.invalid/bad.tar.gz", "digest": "sha256:$BAD_SHA256"},
    {"name": "tool-no-digest.zip", "browser_download_url": "https://example.invalid/no-digest.zip", "digest": null}
  ]
}
EOF

mkdir -p "$TEST_ROOT/bin"
cat >"$TEST_ROOT/bin/curl" <<'EOF'
#!/usr/bin/env bash
# Offline curl stand-in: emits $GH_TEST_JSON for API queries (no -o) and
# copies $GH_TEST_PAYLOAD to the -o destination for asset downloads.
set -euo pipefail
out=''
while (($#)); do
    case "$1" in
    -o)
        out="$2"
        shift
        ;;
    --retry) shift ;;
    esac
    shift
done
if [[ -n "$out" ]]; then
    cp "$GH_TEST_PAYLOAD" "$out"
else
    cat "$GH_TEST_JSON"
fi
EOF
chmod +x "$TEST_ROOT/bin/curl"
export GH_TEST_JSON="$TEST_ROOT/release.json" GH_TEST_PAYLOAD="$TEST_ROOT/payload"
PATH="$TEST_ROOT/bin:$PATH"

# --- flag parsing ------------------------------------------------------------
gh_parse_force_flag --force
((FORCE == 1)) || fail '--force should set FORCE=1'
gh_parse_force_flag
((FORCE == 0)) || fail 'no arguments should leave FORCE=0'

rc=0
(gh_parse_force_flag --help) >/dev/null || rc=$?
((rc == 0)) || fail "--help should exit 0 (got rc=$rc)"
rc=0
(gh_parse_force_flag --bogus) >/dev/null 2>&1 || rc=$?
((rc == 2)) || fail "an unknown flag should exit 2 (got rc=$rc)"

# --- release resolution ------------------------------------------------------
gh_resolve_latest example/tool
[[ "$GH_TAG" == 'v1.2.3' ]] || fail "GH_TAG should be the raw tag (got $GH_TAG)"
[[ "$GH_VERSION" == '1.2.3' ]] || fail "GH_VERSION should be v-stripped (got $GH_VERSION)"

# --- asset selection, download, and digest verification ----------------------
gh_fetch_asset 'tool_1.2.3_amd64.deb' "$TEST_ROOT/out.deb" >/dev/null
diff -q "$TEST_ROOT/payload" "$TEST_ROOT/out.deb" >/dev/null ||
    fail 'fetched asset differs from the served payload'

gh_fetch_asset_matching 'endswith(".AppImage")' "$TEST_ROOT/out.appimage" >/dev/null ||
    fail 'predicate selection did not fetch the AppImage'

if (gh_fetch_asset 'absent.deb' "$TEST_ROOT/x") >/dev/null 2>&1; then
    fail 'zero matching assets should fail'
fi
if (gh_fetch_asset_matching 'startswith("tool")' "$TEST_ROOT/x") >/dev/null 2>&1; then
    fail 'an ambiguous predicate should fail'
fi
if (gh_fetch_asset 'tool-no-digest.zip' "$TEST_ROOT/x") >/dev/null 2>&1; then
    fail 'a missing digest should fail'
fi
if (gh_fetch_asset 'tool-bad-digest.tar.gz' "$TEST_ROOT/x") >/dev/null 2>&1; then
    fail 'a checksum mismatch should fail'
fi

# --- version comparison ------------------------------------------------------
if command -v dpkg >/dev/null 2>&1; then
    gh_up_to_date 1.2.3 1.2.3 || fail 'equal versions should count as up to date'
    gh_up_to_date 1.10.0 1.9.0 || fail 'a newer install should count as up to date'
    if gh_up_to_date 0.9.0 0.19.2; then
        fail '0.9.0 must not compare >= 0.19.2 (string-compare trap)'
    fi
    if gh_up_to_date '' 1.0.0; then
        fail 'an empty installed version is never up to date'
    fi
fi

echo 'github-release lib tests passed'
