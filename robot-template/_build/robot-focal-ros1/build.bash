#!/bin/bash 
set -e

# Configuration - can be overridden by environment variables
export USER_NAME=${USER_NAME:-user}
export USER_ID=${USER_ID:-1000}
export KERNEL_VER=${KERNEL_VER:-5}
export ROBOT_NAME=${ROBOT_NAME:-robot}
export RECIPES_TAG=${RECIPES_TAG:-main}
export RECIPES_REPO=${RECIPES_REPO:-git@github.com:advrhumanoids/multidof_recipes.git}

# Docker image naming - matches original kyon pattern
TAGNAME=${TAGNAME:-v1.0.0}
BASE_IMAGE_NAME=${BASE_IMAGE_NAME:-${ROBOT_NAME}-cetc-focal-ros1}

echo "Building with configuration:"
echo "  USER_NAME: $USER_NAME"
echo "  USER_ID: $USER_ID"
echo "  KERNEL_VER: $KERNEL_VER"
echo "  ROBOT_NAME: $ROBOT_NAME"
echo "  RECIPES_TAG: $RECIPES_TAG"
echo "  BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "  TAGNAME: $TAGNAME"

# Build the docker images
docker compose build

# Tag the built images (matching original pattern exactly)
docker tag ${BASE_IMAGE_NAME}-base hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
docker tag ${BASE_IMAGE_NAME}-xeno hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
docker tag ${BASE_IMAGE_NAME}-locomotion hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME

# Push the images (matching original pattern exactly)
docker push hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
docker push hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
docker push hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME

echo "Build and push completed successfully!"
echo "Images pushed:"
echo "  hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME"
echo "  hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME"
echo "  hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME"