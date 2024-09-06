#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

xhost local:root

docker run --runtime nvidia --rm -it --gpus all \
 --privileged \
 --env="NVIDIA_DRIVER_CAPABILITIES=all" \
 --env="DISPLAY=$DISPLAY" \
 --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
 --volume="$HOME/.ssh:/home/user/.ssh:ro" \
 xbot2_noble_base:latest \
 bash