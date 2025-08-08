#!/bin/bash 
set -e

# Configuration - can be overridden by environment variables
export USER_NAME=${USER_NAME:-user}
export USER_ID=${USER_ID:-1000}
export KERNEL_VER=${KERNEL_VER:-5}
export ROBOT_NAME=${ROBOT_NAME:-robot}
export RECIPES_TAG=${RECIPES_TAG:-main}
export RECIPES_REPO=${RECIPES_REPO:-git@github.com:advrhumanoids/multidof_recipes.git}

# Docker image naming - matches original nexus pattern
export TAGNAME=${TAGNAME:-v1.0.0}
export BASE_IMAGE_NAME=${BASE_IMAGE_NAME:-${ROBOT_NAME}-cetc-focal-ros1}
# Add registry as a separate variable for flexibility
export DOCKER_REGISTRY=${DOCKER_REGISTRY:-hhcmhub}

# Parse command line arguments
BUILD_MODE="local"  # Default to local build
PUSH_IMAGES="false"  # Default to NOT push
NO_CACHE=""  # Default to use cache

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
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --local          Build images locally (default)"
            echo "  --pull, --remote Pull images from remote registry"
            echo "  --push           Push images to remote registry after building"
            echo "  --no-push        Don't push images (default, kept for compatibility)"
            echo "  --no-cache       Build without using Docker cache"
            echo ""
            echo "Environment variables:"
            echo "  USER_NAME, USER_ID, KERNEL_VER, ROBOT_NAME, RECIPES_TAG"
            echo "  BASE_IMAGE_NAME, TAGNAME, DOCKER_REGISTRY"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build locally, don't push"
            echo "  $0 --push             # Build locally and push"
            echo "  $0 --pull             # Pull from registry"
            echo "  $0 --no-cache         # Build locally without cache"
            echo "  $0 --no-cache --push  # Build without cache and push"
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
echo "  DOCKER_REGISTRY: $DOCKER_REGISTRY"

# Helper function to check if docker buildx is available and set up
ensure_buildx() {
    if ! docker buildx version &> /dev/null; then
        echo "Error: Docker Buildx is not available. Please update Docker."
        exit 1
    fi
    
    # Create a new builder instance if it doesn't exist
    # This ensures we have all features available
    if ! docker buildx ls | grep -wq "builder"; then
        echo "Creating Docker Buildx builder instance..."
        docker buildx create --name builder --driver docker-container --use
    else
        docker buildx use builder
    fi
}

if [ "$BUILD_MODE" == "remote" ]; then
    echo ""
    echo "Pulling images from remote registry..."
    
    # For pulling, we still use direct docker pull commands
    # since bake is primarily for building
    docker pull ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:$TAGNAME
    docker pull ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
    docker pull ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
    
    # Tag them for local use (without registry prefix)
    docker tag ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:$TAGNAME ${BASE_IMAGE_NAME}-base
    docker tag ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME ${BASE_IMAGE_NAME}-xeno
    docker tag ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:$TAGNAME ${BASE_IMAGE_NAME}-locomotion
    
    echo "Images pulled and tagged successfully!"
    
else
    echo ""
    echo "Building images locally using Docker Bake..."
    
    # Ensure buildx is available and configured
    # Only manage the builder's lifecycle if we are NOT in a CI environment.
    # GitHub Actions and other CI systems set the CI variable to 'true'.
    if [ -z "$CI" ]; then
        echo "Local environment detected. Ensuring 'builder' instance exists..."
        ensure_buildx
    else
        echo "CI environment detected. Using the builder provided by the CI environment."
    fi
    
    # Check if docker-bake.hcl exists, if not, fall back to compose
    if [ ! -f "docker-bake.hcl" ]; then
        echo "Warning: docker-bake.hcl not found, falling back to docker compose..."
        echo "Consider creating a docker-bake.hcl file for better dependency management."
        
        # Fallback to original compose behavior
        docker compose build $NO_CACHE
        
        # Tag the built images for registry
        docker tag ${BASE_IMAGE_NAME}-base ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:$TAGNAME
        docker tag ${BASE_IMAGE_NAME}-xeno ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
        docker tag ${BASE_IMAGE_NAME}-locomotion ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
    else
        # Use Docker Bake for coordinated builds with dependency management
        echo "Using Docker Bake for coordinated build..."
        
        # Prepare bake flags
        BAKE_FLAGS=""
        
        # Add no-cache flag if requested
        if [ -n "$NO_CACHE" ]; then
            BAKE_FLAGS="$BAKE_FLAGS --no-cache"
        fi
        
        # Set output type based on push requirement
        if [ "$PUSH_IMAGES" == "true" ]; then
            # This will build and push in one operation
            BAKE_FLAGS="$BAKE_FLAGS --push"
            echo "Build will push to registry upon completion..."
        else
            # Load images into local Docker daemon
            BAKE_FLAGS="$BAKE_FLAGS --load"
        fi
        
        # Export all variables that the bake file might need
        export DOCKER_REGISTRY
        export BASE_IMAGE_NAME
        export TAGNAME
        export KERNEL_VER
        export USER_NAME
        export USER_ID
        export ROBOT_NAME
        export RECIPES_TAG
        export RECIPES_REPO
        # AUTOMATIC NETRC SECRET HANDLING  
        # Check if the user has a .netrc file in their home directory
        if [ -f "$HOME/.netrc" ]; then
        echo "Found .netrc file, exporting content for build secret..."
        export NETRC_CONTENT=$(cat "$HOME/.netrc")
        else
        # If the file doesn't exist, just print a warning.
        # The build can continue, but will fail if private repos are needed.
        echo "Warning: ~/.netrc not found. Private repository access may fail."
        fi
        
        # Run the bake build
        echo "Executing: docker buildx bake -f docker-bake.hcl $BAKE_FLAGS"
        docker buildx bake -f docker-bake.hcl $BAKE_FLAGS
        
        if [ $? -ne 0 ]; then
            echo "Error: Docker Bake build failed!"
            exit 1
        fi
    fi
    
    echo "Images built successfully!"
    
    # If using bake with --push, the push already happened
    # If using compose fallback, we need to push manually
    if [ "$PUSH_IMAGES" == "true" ] && [ ! -f "docker-bake.hcl" ]; then
        echo ""
        echo "Pushing images to remote registry..."
        
        docker push ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:$TAGNAME
        docker push ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME
        docker push ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:$TAGNAME
        
        echo "Images pushed successfully!"
    fi
fi

echo ""
echo "Operation completed successfully!"
echo ""

# Show what images are available
if [ "$BUILD_MODE" == "local" ] || [ "$BUILD_MODE" == "remote" ]; then
    echo "Local images available:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "${BASE_IMAGE_NAME}" || true
fi

if [ "$PUSH_IMAGES" == "true" ] || [ "$BUILD_MODE" == "remote" ]; then
    echo ""
    echo "Remote images available:"
    echo "  ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:$TAGNAME"
    echo "  ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v$KERNEL_VER:$TAGNAME"
    echo "  ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:$TAGNAME"
fi

# Clean up builder instance on exit (optional)
# trap "docker buildx use default" EXIT