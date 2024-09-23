# Usage

## Build the container
```bash
USER_ID=$(id -u) docker compose build
```
If your user id is 1000 (very common), you can drop the first part.

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
