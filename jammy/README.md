# XBot2 Jammy (Ubuntu 22.04) - ROS2 Humble

This folder contains Docker configurations for XBot2 on Ubuntu 22.04 Jammy with ROS2 Humble.

## Quick Start

### Option 1: Pull Pre-built Images (Recommended)

If you **don't have access** to the xbot2 GitHub repositories, you can pull and use pre-built images:

```bash
# Pull the latest images
docker compose pull

# Start the container with NVIDIA GPU support
docker compose up -d
```

Attach to the running container:
```bash
docker compose exec dev terminator
```

Stop the container:
```bash
docker compose down
```

### Option 2: Build from Source

If you have access to xbot2 GitHub repositories and want to build locally:

#### Build the container
```bash
USER_ID=$(id -u) docker compose build
```

If your user ID is 1000 (very common), you can omit the `USER_ID` part:
```bash
docker compose build
```

#### Start the container
```bash
docker compose up -d
```

#### Attach with terminator
```bash
docker compose exec dev terminator
```

#### Build the whole forest workspace
Inside the container:
```bash
./bootstrap.sh
```

#### Stop the container
```bash
docker compose down
```

## Image Details

The image is pulled from `hhcmhub/` registry:
- `hhcmhub/xbot2-jammy-dev:latest` - Development environment with ROS2 Humble

