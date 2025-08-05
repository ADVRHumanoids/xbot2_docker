#!/bin/bash
TAG_NAME=${GITHUB_REF_NAME:-latest}

docker tag jammy-dev:latest hhcmhub/xbot2-jammy-dev:$TAG_NAME
docker tag jammy-dev:latest hhcmhub/xbot2-jammy-dev:latest
docker push hhcmhub/xbot2-jammy-dev:latest
docker push hhcmhub/xbot2-jammy-dev:$TAG_NAME
