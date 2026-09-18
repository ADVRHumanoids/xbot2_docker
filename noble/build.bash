#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# ----- Defaults -----
USER_ID="${USER_ID:-$(id -u)}"
RECIPES_REPO=""
RECIPES_TAG=""
FOREST_NJOBS="1"
NETRC_FILE=""
TAG="${TAG:-${GITHUB_REF_NAME:-latest}}"
NO_CACHE=""
PUSH=""
SNAPSHOT=""
SNAPSHOT_NAME="$(date +%Y%m%d%H%M)"

# ----- Usage -----
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the xbot2 noble Docker images (base -> robot -> rt-v5/rt-v6) using docker buildx bake.

Options:
  --user-id      ID    UID for the 'user' account inside the container (default: current user)
  --recipes-repo URL   Forest recipes repository URL          [required for robot/rt]
  --recipes-tag  TAG   Forest recipes git tag/branch          [required for robot/rt]
  --forest-njobs N     Parallel jobs for forest grow          (default: 1)
  --netrc        PATH  Path to a .netrc file for private git clones (build secret)
  --tag          TAG   Docker image tag applied to all images (default: TAG, GITHUB_REF_NAME, or latest)
  --no-cache           Pass --no-cache to docker buildx bake
  --push               Push images to the registry instead of only loading them locally
  --snapshot           Run snapshot.bash after a successful build
  --snapshot-name NAME Build name subfolder for the snapshot (default: YYYYMMDDHHmm)
  -h, --help           Show this help message
EOF
}

# ----- Argument parsing -----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --user-id)      USER_ID="$2";      shift 2 ;;
        --recipes-repo) RECIPES_REPO="$2"; shift 2 ;;
        --recipes-tag)  RECIPES_TAG="$2";  shift 2 ;;
        --forest-njobs) FOREST_NJOBS="$2"; shift 2 ;;
        --netrc)        NETRC_FILE="$2";   shift 2 ;;
        --tag)          TAG="$2";          shift 2 ;;
        --no-cache)     NO_CACHE="--no-cache"; shift ;;
        --push)         PUSH="1"; shift ;;
        --snapshot)     SNAPSHOT="1"; shift ;;
        --snapshot-name) SNAPSHOT_NAME="$2"; shift 2 ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "Unknown argument: $1"; echo; usage; exit 1 ;;
    esac
done

# ----- Export variables so bake picks them up from the environment -----
export USER_ID
export RECIPES_REPO
export RECIPES_TAG
export FOREST_NJOBS
export NETRC_FILE
export TAG

cd "$DIR"

# When snapshotting, use the snapshot name as the image tag (unless --tag was set explicitly)
if [[ -n "$SNAPSHOT" && "$TAG" == "latest" ]]; then
    TAG="$SNAPSHOT_NAME"
fi

BAKE_ARGS=(-f docker-bake.hcl)
if [[ -n "$NETRC_FILE" ]]; then
    # Filesystem entitlements were added to `buildx bake` in Buildx v0.19.
    # Older releases can still read a local secret source, but reject --allow.
    BUILDX_VERSION="$(docker buildx version 2>/dev/null || true)"
    if [[ "$BUILDX_VERSION" =~ v([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        BUILDX_MAJOR="${BASH_REMATCH[1]}"
        BUILDX_MINOR="${BASH_REMATCH[2]}"
        if (( BUILDX_MAJOR > 0 || BUILDX_MINOR >= 19 )); then
            BAKE_ARGS=(--allow=fs.read="$(realpath "$NETRC_FILE")" "${BAKE_ARGS[@]}")
        fi
    fi
fi
NO_CACHE_ARGS=()
if [[ -n "$NO_CACHE" ]]; then
    NO_CACHE_ARGS+=("$NO_CACHE")
fi

run_image_tests() {
    echo "Running image tests"
    bash "$DIR/test_image.bash"
}

if [[ -n "$SNAPSHOT" ]]; then
    echo "Building images locally with tag: $TAG"
    docker buildx bake "${BAKE_ARGS[@]}" "${NO_CACHE_ARGS[@]}" --load rt

    run_image_tests

    "$DIR/snapshot.bash" --tag "$TAG" --name "$SNAPSHOT_NAME"
fi

if [[ -n "$PUSH" ]]; then
    # Build and test the local images before publishing anything to the registry.
    if [[ -z "$SNAPSHOT" ]]; then
        echo "Building images locally with tag: $TAG"
        docker buildx bake "${BAKE_ARGS[@]}" "${NO_CACHE_ARGS[@]}" --load rt

        run_image_tests
    fi

    echo "Building and pushing images with tag: $TAG"
    # Reuse the cache populated by the local build that just passed the tests.
    docker buildx bake "${BAKE_ARGS[@]}" --push rt
elif [[ -z "$SNAPSHOT" ]]; then
    echo "Building images locally with tag: $TAG"
    docker buildx bake "${BAKE_ARGS[@]}" "${NO_CACHE_ARGS[@]}" --load rt

    run_image_tests
fi
