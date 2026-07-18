# XBot2 Noble (Ubuntu 24.04) - ROS2 Jazzy

This folder contains Docker configurations for XBot2 on Ubuntu 24.04 Noble with ROS2 Jazzy.

## Quick Start

> [!NOTE]
> All the following commands are meant to be executed in this folder.

### Option 1: Pull Pre-built Images (Recommended)

If you **don't have access** to the xbot2 GitHub repositories, use pre-built images:

```bash
# Pull the latest images
docker compose pull

# Start the container
docker compose up -d robot        # For systems WITHOUT NVIDIA GPU
docker compose up -d robot-nvidia # For systems WITH NVIDIA GPU
```

Attach to the running container:
```bash
docker compose exec robot terminator        # or robot-nvidia
```

Stop the container:
```bash
docker compose down
```

### Option 2: Build from Source

If you have access to xbot2 GitHub repositories and want to build locally:

#### Build the container
```bash
./build.bash --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git \
             --user-id $(id -u) \
             --recipes-tag ros2 \
             --forest-njobs 8 \
             --netrc ~/.netrc
```

#### Start the dev container
```bash
docker compose up -d dev         # Without NVIDIA GPU
docker compose up -d dev-nvidia  # With NVIDIA GPU
```

#### Attach with terminator
```bash
docker compose exec dev terminator
```

#### Stop the container
```bash
docker compose down
```

## Available Services

The `compose.yaml` file defines several services:

| Service | Image | GPU Support | Use Case |
|---------|-------|-------------|----------|
| `dev` | `xbot2-noble-dev` | No | Development, building from source |
| `dev-nvidia` | `xbot2-noble-dev` | Yes | Development with GPU |
| `robot` | `xbot2-noble-robot` | No | Pre-built robot image |
| `robot-nvidia` | `xbot2-noble-robot` | Yes | Pre-built robot image with GPU |
| `rt` | `xbot2-noble-rt` | No | Real-time variant |

## Troubleshooting


### Choosing the Right Service

- **robot / robot-nvidia**: Usually this is the way to go since is the version you'll find also in the robot.
- **dev / dev-nvidia**: Use these if you need to build packages from source or customize the installation.
- **rt**: Use this for real-time kernel support (advanced use case).

## Image Details

All images are pulled from `hhcmhub/` registry:
- `hhcmhub/xbot2-noble-dev:latest` - Base development environment
- `hhcmhub/xbot2-noble-robot:latest` - Robot-ready with core packages
- `hhcmhub/xbot2-noble-rt:latest` - Real-time kernel variant
