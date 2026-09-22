#!/bin/bash
# Regenerate static/nathan-genetzky-resume.{png,pdf} from a running Hugo server.
#
# The theme's print stylesheet drops the sidebar and main body, so these artifacts
# are captured from the screen layout with headless Chrome rather than printed.
#
# Usage:
#   hugo server &                 # or: script/serve.bash
#   script/build_capture.bash

set -eu -o pipefail

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="$(CDPATH='' cd -- "${D_SCRIPT}/.." && pwd -P)"

CAPTURE_URL="${CAPTURE_URL:-http://localhost:1313/}"
CAPTURE_WIDTH="${CAPTURE_WIDTH:-1250}"
IMAGE="${CAPTURE_IMAGE:-zenika/alpine-chrome:with-puppeteer}"

docker run --rm --network host \
    -u "$(id -u):$(id -g)" \
    -e CAPTURE_URL="${CAPTURE_URL}" \
    -e CAPTURE_WIDTH="${CAPTURE_WIDTH}" \
    -v "${D_PROJ}/script/capture.js":/usr/src/app/capture.js:ro \
    -v "${D_PROJ}/static":/out \
    -w /usr/src/app \
    "${IMAGE}" node capture.js
