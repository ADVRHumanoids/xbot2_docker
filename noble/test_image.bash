#!/bin/bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR"
docker compose run --rm --no-deps \
    --entrypoint /bin/bash \
    -v "$DIR/test:/home/user/test:ro" \
    dev /home/user/test/run_all.bash
