#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOTS_SOURCE="$REPO_ROOT/_dots/bin/dots"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fixture="$TEST_ROOT/repo"
target="$TEST_ROOT/home"
mkdir -p "$fixture/_dots/bin" "$fixture/alpha/.config/app" "$fixture/beta/.config/other" "$fixture/gamma/.vim" \
    "$fixture/delta/.config/app/cachedir" "$fixture/epsilon/.data" "$target/.config/app"
cp "$DOTS_SOURCE" "$fixture/_dots/bin/dots"
printf '%s\n' '--ignore=ignored[.]cache' '--ignore=local[.]sh' '--ignore=cachedir' >"$fixture/.stowrc"
printf '%s\n' ignored >"$fixture/alpha/.config/app/ignored.cache"
printf '%s\n' tracked >"$fixture/alpha/.config/app/tracked.conf"
printf '%s\n' beta >"$fixture/beta/.config/other/beta.conf"
printf '%s\n' gamma >"$fixture/gamma/.vim/vimrc"
printf '%s\n' machine >"$fixture/delta/.config/app/local.sh"
printf '%s\n' template >"$fixture/delta/.config/app/local.sh.example"
printf '%s\n' cached >"$fixture/delta/.config/app/cachedir/data.txt"
printf '%s\n' real >"$fixture/epsilon/.data/real.txt"
ln -s real.txt "$fixture/epsilon/.data/link.txt"

run_dots() {
    env DOTS_REPO="$fixture" DOTS_TARGET="$target" bash "$fixture/_dots/bin/dots" "$@"
}

expect_rc() {
    local expected="$1" name="$2"
    shift 2
    local output rc
    set +e
    output="$("$@" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -ne "$expected" ]]; then
        printf 'FAIL: %s (expected rc=%s, got rc=%s)\n%s\n' "$name" "$expected" "$rc" "$output" >&2
        exit 1
    fi
    printf '%s' "$output"
}

for command in status diff stow; do
    output="$(expect_rc 2 "invalid package: $command" run_dots "$command" not-a-package)"
    [[ "$output" == *'not a stow package'* ]] || {
        echo "FAIL: $command omitted validation error" >&2
        exit 1
    }
    [[ "$output" != *'all package files resolve'* ]] || {
        echo "FAIL: $command printed false success" >&2
        exit 1
    }
done

output="$(run_dots stow alpha 2>&1)"
[[ "$output" == *'tracked.conf'* ]] || {
    echo 'FAIL: dry run omitted tracked file' >&2
    exit 1
}
[[ "$output" != *'ignored.cache'* ]] || {
    echo 'FAIL: .stowrc ignore was not applied' >&2
    exit 1
}
[[ ! -e "$target/.config/app/tracked.conf" ]] || {
    echo 'FAIL: dry run mutated target' >&2
    exit 1
}

run_dots stow --apply alpha >/dev/null 2>&1
[[ -L "$target/.config/app/tracked.conf" ]] || {
    echo 'FAIL: --apply did not create tracked link' >&2
    exit 1
}
[[ ! -e "$target/.config/app/ignored.cache" ]] || {
    echo 'FAIL: --apply linked ignored file' >&2
    exit 1
}

run_dots stow --no-folding --apply gamma >/dev/null 2>&1
[[ -d "$target/.vim" && ! -L "$target/.vim" ]] || {
    echo 'FAIL: --no-folding did not keep target directory real' >&2
    exit 1
}
[[ -L "$target/.vim/vimrc" ]] || {
    echo 'FAIL: --no-folding did not create an individual file link' >&2
    exit 1
}

run_dots restow --no-folding --apply gamma >/dev/null 2>&1
[[ -d "$target/.vim" && ! -L "$target/.vim" ]] || {
    echo 'FAIL: --no-folding restow refolded target directory' >&2
    exit 1
}
[[ -L "$target/.vim/vimrc" ]] || {
    echo 'FAIL: --no-folding restow lost individual file link' >&2
    exit 1
}

output="$(run_dots stow all alpha 2>&1)"
[[ "$output" == *'alpha beta delta epsilon gamma'* ]] || {
    echo 'FAIL: all expansion was not sorted/deduplicated' >&2
    exit 1
}

# Ignore patterns are anchored like Stow's: local[.]sh must not also swallow
# local.sh.example, while segment patterns (cachedir) ignore directory contents.
output="$(expect_rc 1 'status anchors ignore patterns' run_dots status delta)"
[[ "$output" == *'local.sh.example | MISSING'* ]] || {
    echo 'FAIL: status skipped local.sh.example (unanchored ignore match)' >&2
    exit 1
}
[[ "$output" != *'app/local.sh | MISSING'* ]] || {
    echo 'FAIL: status did not ignore local.sh' >&2
    exit 1
}
[[ "$output" != *'cachedir'* ]] || {
    echo 'FAIL: status did not ignore cachedir contents' >&2
    exit 1
}

# Symlinks inside packages are walked by status/diff, not silently skipped.
output="$(expect_rc 1 'status sees package symlinks' run_dots status epsilon)"
[[ "$output" == *'link.txt | MISSING'* ]] || {
    echo 'FAIL: status skipped package symlink' >&2
    exit 1
}

run_dots stow --apply epsilon >/dev/null 2>&1
run_dots status epsilon >/dev/null 2>&1 || {
    echo 'FAIL: status not clean after stowing symlink package' >&2
    exit 1
}
run_dots diff epsilon >/dev/null 2>&1 || {
    echo 'FAIL: diff not clean after stowing symlink package' >&2
    exit 1
}

echo 'dots tests passed'
