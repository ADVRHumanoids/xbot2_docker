[![Build and Push (xbot2_docker-noble-ROS2)](https://github.com/ADVRHumanoids/xbot2_docker/actions/workflows/build-and-push-noble.yml/badge.svg)](https://github.com/ADVRHumanoids/xbot2_docker/actions/workflows/build-and-push-noble.yml)

# xbot2_docker

Docker images for XBot2. Requires Docker with Buildx.

## Build

From the repository root (replace `noble` with e.g. `resolute` if needed):

```bash
./noble/build.bash \
  --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git \
  --recipes-tag ros2 \
  --forest-njobs 8 \
  --tag my-tag
```

Builds and loads the `dev`, `robot`, `rt-v5`, and `rt-v6` images locally.
Add `--netrc "$HOME/.netrc"` for private repositories.

## Push

Log in with an account that can push to `hhcmhub`, then build and push:

```bash
docker login
./noble/build.bash \
  --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git \
  --recipes-tag ros2 \
  --forest-njobs 8 \
  --tag my-tag \
  --push
```

Publishes `hhcmhub/xbot2-noble-{dev,robot,rt-v5,rt-v6}` with both `my-tag` and
`latest` tags. Resolute uses the same naming with `resolute` in place of `noble`.
