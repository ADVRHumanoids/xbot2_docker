#!/bin/bash
TAG_NAME=${GITHUB_REF_NAME:-latest}
docker tag focal-dev:latest hhcmhub/xbot2-focal-dev:latest
docker tag focal-dev:latest hhcmhub/xbot2-focal-dev:$TAG_NAME
docker push hhcmhub/xbot2-focal-dev:latest
docker push hhcmhub/xbot2-focal-dev:$TAG_NAME
