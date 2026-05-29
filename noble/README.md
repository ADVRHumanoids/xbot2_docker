# Usage

## Build the container
Example:
```bash
./build.bash --recipes-repo https://github.com/advrhumanoids/multidof_recipes.git --user-id 1000 --recipes-tag ros2 --forest-njobs 8 --netrc ~/.netrc 
```

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
