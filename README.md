# XBot2 Docker - Robot Template Build System

This directory provides a generalized, reusable Docker build system for XBot2-based robots. It supports multiple ROS versions and different deployment configurations through a flexible, parameterized approach.

## Overview

The robot-template build system is designed to create Docker images for any robot using the XBot2 framework. Instead of duplicating Dockerfiles for each robot, this system uses environment variables and build arguments to customize the build process for specific robots while maintaining a single set of build templates.

## Directory Structure

```
robot-template/_build/
├── robot-focal-ros1/          # ROS1 (Noetic on Ubuntu Focal)
│   ├── Dockerfile-base        # Core development environment
│   ├── Dockerfile-xeno        # Real-time Xenomai extension
│   ├── Dockerfile-locomotion  # Locomotion control stack
│   ├── build.bash            # Main build orchestrator
│   ├── compose.yml           # Docker Compose for building
│   ├── compose.pull.yml      # Docker Compose for pulling
│   └── scripts/              # Build and environment scripts
│       ├── build-base.bash   # Base software installation
│       ├── build-xeno.bash   # Xenomai-specific builds
│       └── env.bash          # Runtime environment setup
└── robot-noble-ros2/         # ROS2 (Jazzy on Ubuntu Noble)
    ├── Dockerfile-base       # Core development environment
    ├── Dockerfile-xeno       # Real-time Xenomai extension
    ├── Dockerfile-sim        # Simulation environment
    ├── build.bash           # Main build orchestrator
    ├── compose.yml          # Docker Compose for building
    └── scripts/             # Build and environment scripts
```

## Build System Architecture

The build system creates layered Docker images, each serving a specific purpose:

### 1. Base Image
The foundation image includes:
- ROS installation (ROS1 Noetic or ROS2 Jazzy)
- XBot2 desktop full installation
- Development tools (git, vim, terminator, etc.)
- Python environment with required packages
- Robot-specific packages defined by environment variables

### 2. Xenomai Image (Real-time)
Extends the base image with:
- Xenomai real-time kernel support
- EtherCAT master capabilities
- Real-time device drivers
- Special user permissions for real-time operations

### 3. Locomotion Image (ROS1) / Simulation Image (ROS2)
Specialized images containing:
- **ROS1**: Advanced locomotion control libraries (Horizon, Casadi, etc.)
- **ROS2**: MuJoCo simulation environment

## Understanding the Build Process

### Environment Variables

The build system relies on environment variables to customize the build for specific robots. These must be set before running the build script:

```bash
# Robot identification
export ROBOT_NAME=myrobot           # Used in paths and package names
export USER_NAME=user               # Username inside containers
export USER_ID=1000                 # Should match your host user ID
export KERNEL_VER=5                 # Xenomai kernel version

# Software configuration
export RECIPES_TAG=main             # Git branch/tag for recipes
export RECIPES_REPO=git@github.com:advrhumanoids/multidof_recipes.git

# Package selection
export ROBOT_PACKAGES="package1 package2"  # Robot-specific packages
export ADDITIONAL_PACKAGES="sensor_driver" # Extra packages

# Image naming
export BASE_IMAGE_NAME=myrobot-focal-ros1  # Base name for images
export TAGNAME=v1.0.0                      # Version tag
```

### The build.bash Script

The main build script provides a unified interface for building, pulling, and pushing Docker images. Here's how to use it:

#### Basic Usage

```bash
cd robot-focal-ros1/  # or robot-noble-ros2/

# Show help
./build.bash --help

# Build locally (default behavior)
./build.bash

# Build locally and push to registry
./build.bash --push

# Pull pre-built images from registry
./build.bash --pull
```

#### What Each Flag Does

**`--local` (default)**
- Builds all images locally using Docker Compose
- Tags images with both local and registry names
- Does not push to registry
- Useful for development and testing

**`--push`**
- Builds all images locally
- Tags images appropriately
- Pushes to the configured Docker registry
- Requires authentication to the registry

**`--pull` or `--remote`**
- Downloads pre-built images from the registry
- Tags them for local use
- Faster than building from scratch
- Requires registry access

### Build Flow Explained

When you run `./build.bash`, the following sequence occurs:

1. **Configuration Loading**
   The script reads all environment variables and validates the configuration. If critical variables are missing, it will fail early with an error message.

2. **Docker Compose Orchestration**
   For local builds, the script uses `docker compose build`, which:
   - Reads `compose.yml` to understand service dependencies
   - Builds images in the correct order (base → xeno/locomotion)
   - Passes environment variables as build arguments
   - Mounts secrets (like `.netrc`) for private repository access

3. **Multi-stage Building**
   Each Dockerfile uses multi-stage builds:
   ```dockerfile
   FROM base_image
   ARG USER_ID=1000
   # Install dependencies
   RUN --mount=type=secret,id=netrc ...
   ```
   This approach keeps images smaller and build secrets secure.

4. **Image Tagging**
   After building, images are tagged following this pattern:
   - Local: `${BASE_IMAGE_NAME}-base`
   - Registry: `hhcmhub/${BASE_IMAGE_NAME}-base:${TAGNAME}`

5. **Optional Push**
   If `--push` is specified, images are uploaded to the registry for team sharing.

## Dockerfile Deep Dive

### Base Dockerfile Structure

Let's examine the key sections of `Dockerfile-base`:

```dockerfile
FROM hhcmhub/xbot2-focal-dev:latest
# Uses official XBot2 development image as starting point

ARG USER_ID=1000
ARG ROBOT_NAME=robot
ARG RECIPES_TAG=main
# Build arguments allow customization

USER root
RUN apt-get update && apt-get install -y \
    xbot2_desktop_full \
    ros-noetic-realsense2-camera
# System-wide package installation

USER $USER_NAME
WORKDIR /home/$USER_NAME

# Use mounted secrets for private repo access
RUN --mount=type=secret,id=netrc,uid=$USER_ID \
    /bin/bash scripts/build-base.bash
```

Key design decisions:
- Starts from official XBot2 base images
- Uses build arguments for flexibility
- Switches between root and user for appropriate permissions
- Leverages BuildKit secrets for secure private repo access

### Build Scripts

The `scripts/build-*.bash` files contain the actual software installation logic:

**build-base.bash**
```bash
# Initialize forest workspace
mkdir xbot2_ws && cd xbot2_ws
forest init
source setup.bash

# Add recipes repository with specified tag
forest add-recipes $RECIPES_REPO -t $RECIPES_TAG

# Build core packages
forest grow xbot2_gui_server
forest grow xbot2_tools -j8

# Build robot-specific packages
for package in $ROBOT_PACKAGES; do
    forest grow $package -j8 -v
done
```


This script:
- Sets up the forest build system
- Configures recipe repositories
- Builds packages in parallel where possible
- Cleans up build artifacts to reduce image size
