#!/bin/bash
TAG_NAME=${GITHUB_REF_NAME:-latest}

docker tag noble-dev:latest hhcmhub/xbot2-noble-dev:$TAG_NAME
docker tag noble-dev:latest hhcmhub/xbot2-noble-dev:latest
docker push hhcmhub/xbot2-noble-dev:latest
docker push hhcmhub/xbot2-noble-dev:$TAG_NAME