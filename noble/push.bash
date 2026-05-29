#!/bin/bash
set -e

# Tag to push. Priority: --tag arg > $GITHUB_REF_NAME > latest
TAG_NAME="${GITHUB_REF_NAME:-latest}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag) TAG_NAME="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

echo "Pushing images with tag: $TAG_NAME"

docker push "hhcmhub/xbot2-noble-dev:$TAG_NAME"
docker push "hhcmhub/xbot2-noble-robot:$TAG_NAME"
docker push "hhcmhub/xbot2-noble-rt:$TAG_NAME"
