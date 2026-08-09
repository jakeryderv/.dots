#!/usr/bin/env bash
# link.sh - manifest-driven symlink deployer for ~/.dots.
#
# Reads the repo-root manifest and links its sources to their $HOME targets. Files are
# enumerated with `git ls-files`, so .gitignore is the only ignore list: an
# untracked file is never deployed. There is no second ignore syntax to keep in
# sync, and no folding heuristic -- the manifest's MODE column states the
# intended topology outright.
#
# Usage: link.sh {status|plan|apply|unlink|diff} [PKG...]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/manifest"

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m' RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' DIM=$'\033[2m' RESET=$'\033[0m'
else
    BOLD='' RED='' GREEN='' YELLOW='' DIM='' RESET=''
fi

err() { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
ok() { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$*"; }

# Two paths are the same deployment if they resolve to the same inode target.
# readlink -f yields the empty string for a path that does not exist, so an
# absent target must never compare equal to an absent source.
same_path() {
    local a b
    a="$(readlink -f "$1" 2>/dev/null || true)"
    b="$(readlink -f "$2" 2>/dev/null || true)"
    [[ -n "$a" && "$a" == "$b" ]]
}

expand_target() {
    local t="$1"
    t="${t//\$XDG_CONFIG_HOME/$XDG_CONFIG_HOME}"
    t="${t//\$XDG_DATA_HOME/$XDG_DATA_HOME}"
    t="${t//\$HOME/$HOME}"
    printf '%s\n' "$t"
}

pretty() { printf '%s\n' "${1/#$HOME/\~}"; }

# A package name that matches no manifest row would filter every row out and
# turn the command into a silent no-op -- the same failure mode the manifest
# checks guard against at apply time, so a typo must be loud here too.
require_known_pkgs() {
    local -a known=()
    local pkg w hit bad=0
    while read -r pkg _; do
        if [[ -z "$pkg" || "$pkg" == \#* ]]; then
            continue
        fi
        known+=("$pkg")
    done <"$MANIFEST"
    for w in "$@"; do
        hit=0
        for pkg in "${known[@]}"; do
            if [[ "$w" == "$pkg" ]]; then
                hit=1
            fi
        done
        if ((hit == 0)); then
            err "unknown package: $w (list them with \`just packages\`)"
            bad=1
        fi
    done
    ((bad == 0))
}

# Emit "MODE<TAB>SOURCE<TAB>EXPANDED_TARGET" for each manifest row, optionally
# filtered to the packages named in "$@". PKG is read from the manifest rather
# than derived from SOURCE: once a package moves to the flat layout the first
# path segment is the XDG category (config, home, data, bin), not the package.
rows() {
    local -a want=("$@")
    local pkg mode src dst w hit
    while read -r pkg mode src dst _; do
        if [[ -z "$pkg" || "$pkg" == \#* ]]; then
            continue
        fi
        if ((${#want[@]})); then
            hit=0
            for w in "${want[@]}"; do
                if [[ "$w" == "$pkg" ]]; then
                    hit=1
                fi
            done
            if ((hit == 0)); then
                continue
            fi
        fi
        printf '%s\t%s\t%s\n' "$mode" "$src" "$(expand_target "$dst")"
    done <"$MANIFEST"
}

# Emit "ABS_SOURCE<TAB>ABS_TARGET" for every symlink a row implies.
pairs() {
    local mode="$1" src="$2" dst="$3"
    local f rel
    case "$mode" in
    link)
        printf '%s\t%s\n' "$REPO_ROOT/$src" "$dst"
        ;;
    tree)
        while IFS= read -r f; do
            rel="${f#"$src"/}"
            printf '%s\t%s\n' "$REPO_ROOT/$f" "$dst/$rel"
        done < <(git -C "$REPO_ROOT" ls-files -- "$src")
        ;;
    *)
        err "unknown mode '$mode' for $src"
        return 1
        ;;
    esac
}

# Per-file resolution tally for a directory source: "OK MISSING CONFLICT".
count_files() {
    local src="$1" dst="$2"
    local ok=0 missing=0 conflict=0 f rel target
    while IFS= read -r f; do
        rel="${f#"$src"/}"
        target="$dst/$rel"
        if [[ -L "$target" || -e "$target" ]]; then
            if same_path "$target" "$REPO_ROOT/$f"; then
                ok=$((ok + 1))
            else
                conflict=$((conflict + 1))
            fi
        else
            missing=$((missing + 1))
        fi
    done < <(git -C "$REPO_ROOT" ls-files -- "$src")
    printf '%d %d %d\n' "$ok" "$missing" "$conflict"
}

# Classify one row: "STATE DETAIL". States that mean everything resolves but the
# topology differs from the manifest are reported separately from real problems,
# because that difference is exactly the phase-2 migration work list.
row_state() {
    local mode="$1" src="$2" dst="$3"
    local abs="$REPO_ROOT/$src"
    local ok missing conflict

    if [[ -L "$dst" ]] && same_path "$dst" "$abs"; then
        if [[ "$mode" == link ]]; then
            printf 'ok -\n'
        else
            printf 'folded dir-symlink,-files-resolve\n'
        fi
        return
    fi

    if [[ ! -e "$dst" && ! -L "$dst" ]]; then
        printf 'missing -\n'
        return
    fi

    if [[ -d "$dst" && -d "$abs" ]]; then
        read -r ok missing conflict < <(count_files "$src" "$dst")
        if ((missing == 0 && conflict == 0)); then
            if [[ "$mode" == link ]]; then
                printf 'unfolded %d-files-resolve\n' "$ok"
            else
                printf 'ok %d-files\n' "$ok"
            fi
        else
            printf 'partial ok=%d,missing=%d,conflict=%d\n' "$ok" "$missing" "$conflict"
        fi
        return
    fi

    printf 'conflict not-a-link-into-repo\n'
}

cmd_status() {
    local mode src dst state detail
    local problems=0 drift=0 clean=0

    printf '%sManifest status%s\n' "$BOLD" "$RESET"
    printf '  repo:   %s\n' "$REPO_ROOT"
    printf '  config: %s\n' "$XDG_CONFIG_HOME"
    printf '  data:   %s\n\n' "$XDG_DATA_HOME"

    while IFS=$'\t' read -r mode src dst; do
        read -r state detail < <(row_state "$mode" "$src" "$dst")
        case "$state" in
        ok)
            clean=$((clean + 1))
            printf '  %sok%s        %-4s %-44s %s\n' "$GREEN" "$RESET" "$mode" "$(pretty "$dst")" "$DIM$detail$RESET"
            ;;
        folded | unfolded)
            drift=$((drift + 1))
            printf '  %s%-9s%s %-4s %-44s %s\n' "$YELLOW" "$state" "$RESET" "$mode" "$(pretty "$dst")" "$DIM$detail$RESET"
            ;;
        *)
            problems=$((problems + 1))
            printf '  %s%-9s%s %-4s %-44s %s\n' "$RED" "$state" "$RESET" "$mode" "$(pretty "$dst")" "$DIM$detail$RESET"
            ;;
        esac
    done < <(rows "$@")

    printf '\n  %d matching manifest, %d topology drift, %d problem(s)\n' "$clean" "$drift" "$problems"
    if ((drift)); then
        printf '  %sdrift%s means every file resolves into the repo, but the link shape\n' "$YELLOW" "$RESET"
        printf '        differs from the manifest MODE. Harmless; resolved in phase 2.\n'
    fi
    ((problems == 0))
}

# Create or repoint one symlink. Returns 1 on an unresolvable conflict.
place() {
    local src="$1" dst="$2" apply="$3"

    # Already deployed. Test resolution before testing link-ness: a target can
    # resolve to its source through a symlinked ancestor directory (stow folds
    # at arbitrary depths, e.g. ~/.claude/hooks) without being a symlink itself.
    if same_path "$dst" "$src"; then
        return 0
    fi

    if [[ -L "$dst" ]]; then
        printf '  %-8s %s\n' "relink" "$(pretty "$dst")"
        if ((apply)); then
            ln -sfn "$src" "$dst"
        fi
        return 0
    fi

    if [[ -e "$dst" ]]; then
        # A real directory whose tracked files all already resolve into the
        # source is not a conflict -- it is a link-mode row still carrying the
        # unfolded topology stow left behind. Report it as migration work, not
        # as breakage. Collapsing it means removing the real directory, which
        # this command will not do silently.
        local ok missing conflict
        if [[ -d "$dst" && -d "$src" ]]; then
            read -r ok missing conflict < <(count_files "${src#"$REPO_ROOT/"}" "$dst")
            if ((missing == 0 && conflict == 0)); then
                printf '  %sunfolded%s %s %s(%d files already resolve; collapse by hand in phase 2)%s\n' \
                    "$YELLOW" "$RESET" "$(pretty "$dst")" "$DIM" "$ok" "$RESET"
                return 2
            fi
        fi
        printf '  %sCONFLICT%s %s %s(existing real file -- remove or adopt it)%s\n' \
            "$RED" "$RESET" "$(pretty "$dst")" "$DIM" "$RESET"
        return 1
    fi

    printf '  %-8s %s\n' "link" "$(pretty "$dst")"
    if ((apply)); then
        mkdir -p "$(dirname "$dst")"
        ln -s "$src" "$dst"
    fi
    return 0
}

cmd_link() {
    local apply="$1"
    shift
    local mode src dst s t rc conflicts=0 unfolded=0 changes=0

    if ((apply)); then
        printf '%sApplying%s\n' "$BOLD" "$RESET"
    else
        printf '%sDry run%s (nothing will be modified; use `just apply` to commit)\n' "$BOLD" "$RESET"
    fi

    while IFS=$'\t' read -r mode src dst; do
        while IFS=$'\t' read -r s t; do
            rc=0
            place "$s" "$t" "$apply" || rc=$?
            case "$rc" in
            0) changes=$((changes + 1)) ;;
            2) unfolded=$((unfolded + 1)) ;;
            *) conflicts=$((conflicts + 1)) ;;
            esac
        done < <(pairs "$mode" "$src" "$dst")
    done < <(rows "$@")

    printf '\n  %d link(s) in scope, %d unfolded, %d conflict(s)\n' "$changes" "$unfolded" "$conflicts"
    ((conflicts == 0))
}

cmd_unlink() {
    local mode src dst s t removed=0
    while IFS=$'\t' read -r mode src dst; do
        while IFS=$'\t' read -r s t; do
            if [[ -L "$t" ]] && same_path "$t" "$s"; then
                printf '  %-8s %s\n' "unlink" "$(pretty "$t")"
                rm "$t"
                removed=$((removed + 1))
            fi
        done < <(pairs "$mode" "$src" "$dst")
    done < <(rows "$@")
    printf '\n  %d link(s) removed\n' "$removed"
}

# Show content differences for targets that are real files rather than links
# into the repo. A correctly deployed target cannot differ from its source --
# it *is* its source -- so anything printed here is a target that drifted.
cmd_diff() {
    local mode src dst s t shown=0
    while IFS=$'\t' read -r mode src dst; do
        while IFS=$'\t' read -r s t; do
            if same_path "$t" "$s"; then
                continue
            fi
            if [[ ! -e "$t" && ! -L "$t" ]]; then
                warn "missing in target: $(pretty "$t")"
                shown=1
                continue
            fi
            shown=1
            printf '\n%s== %s ==%s\n' "$BOLD" "$(pretty "$t")" "$RESET"
            if [[ -f "$s" && -f "$t" ]] && file "$s" "$t" | grep -q 'text'; then
                diff -u "$t" "$s" || true
            else
                warn "differs and is not a text file pair"
            fi
        done < <(pairs "$mode" "$src" "$dst")
    done < <(rows "$@")

    if ((shown == 0)); then
        ok "no differences; every target resolves to its repo source"
    fi
}

main() {
    if [[ ! -f "$MANIFEST" ]]; then
        err "manifest not found: $MANIFEST"
        exit 1
    fi

    local cmd="${1:-status}"
    shift || true

    case "$cmd" in
    status | plan | apply | unlink | diff) ;;
    *)
        err "unknown command: $cmd"
        printf 'usage: link.sh {status|plan|apply|unlink|diff} [PKG...]\n' >&2
        exit 2
        ;;
    esac

    require_known_pkgs "$@" || exit 2

    case "$cmd" in
    status) cmd_status "$@" ;;
    plan) cmd_link 0 "$@" ;;
    apply) cmd_link 1 "$@" ;;
    unlink) cmd_unlink "$@" ;;
    diff) cmd_diff "$@" ;;
    esac
}

main "$@"
