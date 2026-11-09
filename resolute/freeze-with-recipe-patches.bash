#!/usr/bin/env bash
set -euo pipefail

# Forest refuses to lock dirty Git checkouts. The osqp Forest recipe patches
# CMakeLists.txt (including a nested submodule) before building, so temporarily
# reverse that *recipe-owned* patch while writing forest.lock and restore it
# before leaving. Keep unexpected changes visible instead of resetting repos.
cd "$(dirname "$0")"

osqp_dir="$PWD/src/osqp"
osqp_patch="$PWD/recipes/multidof_recipes/patch/osqp/osqp-00.patch"
patch_reversed=0

restore_patch() {
    status=$?
    trap - EXIT
    if (( patch_reversed )); then
        if ! git -C "$osqp_dir" apply "$osqp_patch"; then
            echo "ERROR: could not restore the osqp recipe patch after forest freeze" >&2
            exit 1
        fi
    fi
    exit "$status"
}
trap restore_patch EXIT

if [[ -d "$osqp_dir/.git" && -f "$osqp_patch" ]]; then
    if git -C "$osqp_dir" apply --reverse --check "$osqp_patch"; then
        echo "Temporarily reversing the osqp recipe patch for forest freeze"
        git -C "$osqp_dir" apply --reverse "$osqp_patch"
        patch_reversed=1

        # Fail rather than silently hide edits that are not part of the recipe.
        if [[ -n "$(git -C "$osqp_dir" status --porcelain)" ]]; then
            echo "ERROR: osqp contains changes beyond the recipe patch" >&2
            git -C "$osqp_dir" status --short >&2
            exit 1
        fi
    fi
fi

forest freeze --append
