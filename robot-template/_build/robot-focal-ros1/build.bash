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
PUSH_IMAGES="false"  # Default to NOT push
BUILD_TARGETS=()  # Array to store what to build
USE_NO_CACHE=""  # Flag for --no-cache

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
            PUSH_IMAGES="false"
            shift
            ;;
        --base)
            BUILD_TARGETS+=("base")
            shift
            ;;
        --xeno)
            BUILD_TARGETS+=("xeno")
            shift
            ;;
        --locomotion)
            BUILD_TARGETS+=("locomotion")
            shift
            ;;
        --all)
            BUILD_TARGETS=("base" "xeno" "locomotion")
            shift
            ;;
        --no-cache)
            USE_NO_CACHE="--no-cache"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Build options:"
            echo "  --base           Build only base image"
            echo "  --xeno           Build only xeno (real-time) image"
            echo "  --locomotion     Build only locomotion image"
            echo "  --all            Build all images (default if no specific target given)"
            echo ""
            echo "Mode options:"
            echo "  --local          Build images locally (default)"
            echo "  --pull, --remote Pull images from remote registry"
            echo "  --push           Push images to remote registry after building"
            echo "  --no-push        Don't push images (default)"
            echo ""
            echo "Docker build options:"
            echo "  --no-cache       Build without using cache"
            echo ""
            echo "Examples:"
            echo "  $0                         # Build all images locally"
            echo "  $0 --base                  # Build only base image"
            echo "  $0 --xeno --push           # Build only xeno image and push"
            echo "  $0 --base --no-cache       # Build base image without cache"
            echo "  $0 --all --push --no-cache # Build all images without cache and push"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# If no specific build targets specified, build all
if [ ${#BUILD_TARGETS[@]} -eq 0 ]; then
    BUILD_TARGETS=("base" "xeno" "locomotion")
fi

echo "Configuration:"
echo "  BUILD_MODE: $BUILD_MODE"
echo "  BUILD_TARGETS: ${BUILD_TARGETS[*]}"
echo "  PUSH_IMAGES: $PUSH_IMAGES"
echo "  NO_CACHE: ${USE_NO_CACHE:-"false"}"
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
    
    # Pull only the requested images
    for target in "${BUILD_TARGETS[@]}"; do
        case $target in
            "base")
                echo "Pulling base image..."
                docker pull hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
                docker tag hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME ${BASE_IMAGE_NAME}-base
                ;;
            "xeno")
                echo "Pulling xeno image..."
                docker pull hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
                docker tag hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME ${BASE_IMAGE_NAME}-xeno
                ;;
            "locomotion")
                echo "Pulling locomotion image..."
                docker pull hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
                docker tag hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME ${BASE_IMAGE_NAME}-locomotion
                ;;
        esac
    done
    
    echo "Images pulled and tagged successfully!"
    
else
    echo ""
    echo "Building images locally..."
    
    # Build only the specified targets
    for target in "${BUILD_TARGETS[@]}"; do
        echo "Building $target image..."
        if [ -n "$USE_NO_CACHE" ]; then
            echo "Building without cache..."
            docker compose build $USE_NO_CACHE $target
        else
            docker compose build $target
        fi
    done
    
    echo ""
    echo "Tagging built images..."
    
    # Tag only the built images
    for target in "${BUILD_TARGETS[@]}"; do
        case $target in
            "base")
                echo "Tagging base image..."
                docker tag ${BASE_IMAGE_NAME}-base hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
                ;;
            "xeno")
                echo "Tagging xeno image..."
                docker tag ${BASE_IMAGE_NAME}-xeno hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
                ;;
            "locomotion")
                echo "Tagging locomotion image..."
                docker tag ${BASE_IMAGE_NAME}-locomotion hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
                ;;
        esac
    done
    
    if [ "$PUSH_IMAGES" == "true" ]; then
        echo ""
        echo "Pushing images to remote registry..."
        
        # Push only the built images
        for target in "${BUILD_TARGETS[@]}"; do
            case $target in
                "base")
                    echo "Pushing base image..."
                    docker push hhcmhub/${BASE_IMAGE_NAME}-base:$TAGNAME
                    ;;
                "xeno")
                    echo "Pushing xeno image..."
                    docker push hhcmhub/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
                    ;;
                "locomotion")
                    echo "Pushing locomotion image..."
                    docker push hhcmhub/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
                    ;;
            esac
        done
        
        echo ""
        echo "Images pushed successfully!"
    else
        echo ""
        echo "Images built locally. Use --push to upload to registry."
    fi
fi

echo ""
echo "Operation completed successfully!"