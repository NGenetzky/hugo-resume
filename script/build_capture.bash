#!/bin/bash
# Regenerate static/nathan-genetzky-resume.{png,pdf} and the black-and-white
# nathan-genetzky-resume-bw.pdf from a running Hugo server.
#
# styles-1-compact.css sets `page-break-before: always` on .main-wrapper and
# positions the sidebar absolutely, so printing the page directly paginates
# badly. These artifacts are captured from the screen layout instead.
#
# Usage:
#   hugo server &                 # or: script/serve.bash
#   script/build_capture.bash
#
# Tunables: CAPTURE_URL, CAPTURE_WIDTH (layout width in px), CAPTURE_MARGIN
# (minimum page margin in inches), CAPTURE_IMAGE.

set -eu -o pipefail

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="$(CDPATH='' cd -- "${D_SCRIPT}/.." && pwd -P)"

CAPTURE_URL="${CAPTURE_URL:-http://localhost:1313/}"
CAPTURE_WIDTH="${CAPTURE_WIDTH:-1250}"
CAPTURE_MARGIN="${CAPTURE_MARGIN:-0.25}"
IMAGE="${CAPTURE_IMAGE:-zenika/alpine-chrome:with-puppeteer}"

capture(){
    docker run --rm --network host \
        -u "$(id -u):$(id -g)" \
        -e CAPTURE_URL="$1" \
        -e CAPTURE_OUT="$2" \
        -e CAPTURE_SKIP_PNG="${3:-0}" \
        -e CAPTURE_WIDTH="${CAPTURE_WIDTH}" \
        -e CAPTURE_MARGIN="${CAPTURE_MARGIN}" \
        -v "${D_PROJ}/script/capture.js":/usr/src/app/capture.js:ro \
        -v "${D_PROJ}/static":/out \
        -w /usr/src/app \
        "${IMAGE}" node capture.js
}

capture "${CAPTURE_URL}" nathan-genetzky-resume 0
# The B&W sheet is a print fallback, so skip the png and avoid a second large
# binary in the repo.
capture "${CAPTURE_URL%/}/bw/" nathan-genetzky-resume-bw 1
