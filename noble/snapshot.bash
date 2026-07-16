#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# ----- Defaults -----
TAG="latest"
BUILD_NAME="$(date +%Y%m%d%H%M)"

# ----- Usage -----
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Extract software version snapshots from the built xbot2 noble images.
Snapshots are saved under snapshots/<BUILD_NAME>/{base,robot,rt-v5,rt-v6}/.

Options:
  --tag         TAG   Docker image tag to snapshot (default: latest)
  --name        NAME  Build name used as subfolder (default: YYYYMMDDHHmm)
  -h, --help          Show this help message
EOF
}

# ----- Argument parsing -----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)   TAG="$2";        shift 2 ;;
        --name)  BUILD_NAME="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1"; echo; usage; exit 1 ;;
    esac
done

SNAPSHOT_DIR="$DIR/snapshots/$BUILD_NAME"
echo "Saving snapshot to $SNAPSHOT_DIR"

# ----- Helper: extract from one image -----
# Usage: extract_image <image> <outdir> <has_forest_ws>
extract_image() {
    local image="$1"
    local outdir="$2"
    local has_forest_ws="$3"

    mkdir -p "$outdir"

    echo "  [$image] extracting image digest..."
    {
        echo "image_id: $(docker inspect "$image" --format '{{.Id}}')"
        local digests
        digests=$(docker inspect "$image" --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}')
        if [[ -n "$digests" ]]; then
            echo "repo_digests:"
            echo "$digests" | sed 's/^/  /'
        fi
    } > "$outdir/image-digest.txt"

    echo "  [$image] extracting apt sources..."
    docker run --rm "$image" bash -c \
        'cat /etc/apt/sources.list 2>/dev/null; cat /etc/apt/sources.list.d/*.list 2>/dev/null || true' \
        > "$outdir/apt-sources.txt"

    echo "  [$image] extracting apt packages..."
    docker run --rm "$image" \
        dpkg-query -W -f='${Package}=${Version}\n' \
        > "$outdir/apt.txt"

    echo "  [$image] extracting pip packages..."
    docker run --rm "$image" bash -ic \
        'pip freeze 2>/dev/null || true' \
        > "$outdir/pip.txt"

    if [[ "$has_forest_ws" == "1" ]]; then
        echo "  [$image] extracting forest.lock..."
        docker run --rm "$image" bash -ic \
            'cat ~/xbot2_ws/forest.lock 2>/dev/null || echo "forest.lock not found"' \
            > "$outdir/forest.lock"
    fi

    echo "  [$image] done -> $outdir"
}

# ----- Extract from each image -----
extract_image "hhcmhub/xbot2-noble-dev:${TAG}"   "$SNAPSHOT_DIR/base"  0
extract_image "hhcmhub/xbot2-noble-robot:${TAG}"  "$SNAPSHOT_DIR/robot" 1
extract_image "hhcmhub/xbot2-noble-rt-v5:${TAG}"  "$SNAPSHOT_DIR/rt-v5" 1
extract_image "hhcmhub/xbot2-noble-rt-v6:${TAG}"  "$SNAPSHOT_DIR/rt-v6" 1

echo ""
echo "Snapshot complete: $SNAPSHOT_DIR"
echo "  base/  image-digest.txt  apt-sources.txt  apt.txt  pip.txt"
echo "  robot/ image-digest.txt  apt-sources.txt  apt.txt  pip.txt  forest.lock"
echo "  rt-v5/ image-digest.txt  apt-sources.txt  apt.txt  pip.txt  forest.lock"
echo "  rt-v6/ image-digest.txt  apt-sources.txt  apt.txt  pip.txt  forest.lock"
