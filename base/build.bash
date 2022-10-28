#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

docker build --pull --tag xbot2_focal_base:latest . -f $DIR/Dockerfile
docker build --tag xbot2_focal_base_nvidia:latest . -f $DIR/Dockerfile-nvidia