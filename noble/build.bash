#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

USER_ID=${USER_ID:-$(id -u)} docker compose build --pull
