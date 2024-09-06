#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

docker run --runtime nvidia --rm -it --gpus all \
 --env="NVIDIA_DRIVER_CAPABILITIES=all" \
 --env="DISPLAY=$DISPLAY" \
 --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
 --volume="$HOME/.ssh:/home/user/.ssh:ro" \
 --name modular_description \
 xbot2_focal_base:latest \
 x-terminal-emulator