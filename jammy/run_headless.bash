#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

mkdir -p data
docker compose up -d --no-recreate
docker compose exec dev bash