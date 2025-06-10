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
export TAGNAME=${TAGNAME:-v1.0.0}
export BASE_IMAGE_NAME=${BASE_IMAGE_NAME:-${ROBOT_NAME}-cetc-focal-ros1}

# Parse command line arguments
BUILD_MODE="local"  # Default to local build
PUSH_IMAGES="false"  # Default to NOT push (changed from "true")

while [[ $# -gt 0 ]]; do
    case $1 in
        --pull|--remote)
            BUILD_MODE="remote"
            shift
            ;;
        --local)
            BUILD_MODE="local"
            shift
            ;;
        --push)
            PUSH_IMAGES="true"
            shift
            ;;
        --no-push)
            # Keep for backward compatibility
            PUSH_IMAGES="false"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --local          Build images locally (default)"
            echo "  --pull, --remote Pull images from remote registry"
            echo "  --push           Push images to remote registry after building"
            echo "  --no-push        Don't push images (default, kept for compatibility)"
            echo ""
            echo "Environment variables:"
            echo "  USER_NAME, USER_ID, KERNEL_VER, ROBOT_NAME, RECIPES_TAG"
            echo "  BASE_IMAGE_NAME, TAGNAME, REGISTRY"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build locally, don't push"
            echo "  $0 --push             # Build locally and push"
            echo "  $0 --pull             # Pull from registry"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Configuration:"
echo "  BUILD_MODE: $BUILD_MODE"
echo "  PUSH_IMAGES: $PUSH_IMAGES"
echo "  USER_NAME: $USER_NAME"
echo "  USER_ID: $USER_ID"
echo "  KERNEL_VER: $KERNEL_VER"
echo "  ROBOT_NAME: $ROBOT_NAME"
echo "  RECIPES_TAG: $RECIPES_TAG"
echo "  BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "  TAGNAME: $TAGNAME"


if [ "$BUILD_MODE" == "remote" ]; then
    echo ""
    echo "Pulling images from remote registry..."
    
    # Pull the images
    docker compose -f compose.pull.yml pull
    echo "Images pulled and tagged successfully!"
    
else
    echo ""
    echo "Building images locally..."
    
    # Build the docker images
    docker compose build
    
    # Tag the built images (matching original pattern exactly)    
    # Tag the built images
    docker tag ${BASE_IMAGE_NAME}-base hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
    docker tag ${BASE_IMAGE_NAME}-xeno hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
    docker tag ${BASE_IMAGE_NAME}-locomotion hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
    
    if [ "$PUSH_IMAGES" == "true" ]; then
        echo ""
        echo "Pushing images to remote registry..."
        
        # Push the images
        docker push hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
        docker push hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
        docker push hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
        
        echo ""
        echo "Images pushed successfully!"
    else
        echo ""
        echo "Images built locally. Use --push to upload to registry."
    fi
fi

echo ""
echo "Operation completed successfully!"
echo ""
echo "Local images available:"
echo "  ${BASE_IMAGE_NAME}-base"
echo "  ${BASE_IMAGE_NAME}-xeno"
echo "  ${BASE_IMAGE_NAME}-locomotion"

if [ "$PUSH_IMAGES" == "true" ]; then
    echo ""
    echo "Remote images available:"
    echo "  hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME"
    echo "  hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME"
    echo "  hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME"
fi