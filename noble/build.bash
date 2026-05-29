#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# ----- Defaults -----
USER_ID="${USER_ID:-$(id -u)}"
RECIPES_REPO=""
RECIPES_TAG=""
FOREST_NJOBS="1"
NETRC_FILE=""
TAG="latest"
NO_CACHE=""
SNAPSHOT=""
SNAPSHOT_NAME="$(date +%Y%m%d%H%M)"

# ----- Usage -----
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the xbot2 noble Docker images (base -> robot -> rt) using docker buildx bake.

Options:
  --user-id      ID    UID for the 'user' account inside the container (default: current user)
  --recipes-repo URL   Forest recipes repository URL          [required for robot/rt]
  --recipes-tag  TAG   Forest recipes git tag/branch          [required for robot/rt]
  --forest-njobs N     Parallel jobs for forest grow          (default: 1)
  --netrc        PATH  Path to a .netrc file for private git clones (build secret)
  --tag          TAG   Docker image tag applied to all three images (default: latest)
  --no-cache           Pass --no-cache to docker buildx bake
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

docker buildx bake -f docker-bake.hcl --load $NO_CACHE

if [[ -n "$SNAPSHOT" ]]; then
    "$DIR/snapshot.bash" --tag "$TAG" --name "$SNAPSHOT_NAME"
fi
