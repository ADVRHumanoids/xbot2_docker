# XBot2 Docker - Robot Template Build System

[![Build and Push (xbot2_docker-noble-ROS2)](https://github.com/ADVRHumanoids/xbot2_docker/actions/workflows/build-and-push-noble.yml/badge.svg)](https://github.com/ADVRHumanoids/xbot2_docker/actions/workflows/build-and-push-noble.yml)

Docker images for XBot2 robotics framework, supporting multiple Ubuntu versions and ROS distributions.

## Overview

This repository provides Docker images and build configurations for running XBot2-based robots. Images are available for different Ubuntu versions (Focal, Jammy, Noble) with corresponding ROS distributions.

## Directory Structure

```
xbot2_docker/
├── focal/              # Ubuntu 20.04 (Focal) - ROS1 Noetic
├── jammy/              # Ubuntu 22.04 (Jammy) - ROS2 Humble
└── noble/              # Ubuntu 24.04 (Noble) - ROS2 Jazzy
```

## Quick Start

> [!NOTE]
> All the following commands are meant to be executed in the repo root directory or subfolder when specified by previous `cd` commands

There are two ways to use XBot2 Docker images:

### Option 1: Pull Pre-built Images (Recommended)

If you **don't have access** to the xbot2 GitHub repositories, use pre-built images from the registry:

```bash
cd noble/  # or focal/, jammy/

# Pull the latest images
docker compose pull

# Start the container
docker compose up -d robot        # For systems without NVIDIA GPU
docker compose up -d robot-nvidia # For systems with NVIDIA GPU
```

Attach to the container:
```bash
docker compose exec robot terminator  # or robot-nvidia
```

Stop the container:
```bash
docker compose down
```

### Option 2: Build from Source

If you have access to the xbot2 GitHub repositories and want to customize the build:

```bash
cd noble/  # or focal/, jammy/

# Build with custom configuration
./build.bash --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git \
             --user-id $(id -u) \
             --recipes-tag ros2 \
             --forest-njobs 8 \
             --netrc ~/.netrc \
             --kernel-ver 5.10.172-xeno-ipipe-3.1

# Start the container
docker compose up -d

# Attach with terminator
docker compose exec dev terminator
```

See version-specific READMEs for detailed instructions:
- [focal/README.md](focal/README.md)
- [jammy/README.md](jammy/README.md)
- [noble/README.md](noble/README.md)

## Available Images

| Image | Ubuntu | ROS | Description |
|-------|--------|-----|-------------|
| `xbot2-focal-dev` | 20.04 Focal | ROS1 Noetic | Development environment |
| `xbot2-jammy-dev` | 22.04 Jammy | ROS2 Humble | Development environment |
| `xbot2-noble-dev` | 24.04 Noble | ROS2 Jazzy | Development environment |
| `xbot2-noble-robot` | 24.04 Noble | ROS2 Jazzy | Robot-ready with core packages |
| `xbot2-noble-rt` | 24.04 Noble | ROS2 Jazzy | Real-time (RT) variant |

All images are hosted at `hhcmhub/` registry.
