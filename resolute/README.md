# Usage

## Build the container
Example:
```bash
./build.bash --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git --user-id 1000 --recipes-tag ros2 --forest-njobs 8 --netrc ~/.netrc 
```

## Resolute-specific Forest package branches

The robot image copies `resolute-tag-overrides.yaml` into the Forest workspace and passes it to `forest grow --tag-override`. The real-time images inherit that file and append the `ecat_master` override. This keeps the Resolute `xbot2` branch aligned with XBotBuild without changing the common `ros2` recipes.

To switch branches, edit `resolute-tag-overrides.yaml` before rebuilding.

## Start the container
```bash
docker compose up -d
```

## Attach with terminator
```bash
docker compose exec dev terminator
```

## Build the whole forest workspace
```bash
docker compose exec dev terminator
./bootstrap.sh
```

## Stop the container
```bash
docker compose down
```

## Troubleshooting

### Permission problems when running GUI tools 
Maybe you're not running with nVidia GPU. You need to run `xhost local:root`.
