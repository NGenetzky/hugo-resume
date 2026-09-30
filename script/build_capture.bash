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
# (minimum page margin in inches), CAPTURE_FONT_SCALE, CAPTURE_PAGES,
# CAPTURE_MIN_PT, CAPTURE_HIDE, CAPTURE_IMAGE.
#
# These keep the website's two-column sidebar layout, so they are for people,
# not ATS parsers (see docs/ats-requirements.md). They follow the ATS copy's
# content and print limits: every section, at most CAPTURE_PAGES sheets, and a
# warning when body text falls under CAPTURE_MIN_PT.

set -eu -o pipefail

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="$(CDPATH='' cd -- "${D_SCRIPT}/.." && pwd -P)"

CAPTURE_URL="${CAPTURE_URL:-http://localhost:1313/}"
CAPTURE_WIDTH="${CAPTURE_WIDTH:-1250}"
CAPTURE_MARGIN="${CAPTURE_MARGIN:-0.25}"
CAPTURE_FONT_SCALE="${CAPTURE_FONT_SCALE:-1.6}"
CAPTURE_PAGES="${CAPTURE_PAGES:-2}"
CAPTURE_MIN_PT="${CAPTURE_MIN_PT:-10}"
CAPTURE_HIDE="${CAPTURE_HIDE-}"
IMAGE="${CAPTURE_IMAGE:-zenika/alpine-chrome:with-puppeteer}"

capture(){
    docker run --rm --network host \
        -u "$(id -u):$(id -g)" \
        -e CAPTURE_URL="$1" \
        -e CAPTURE_OUT="$2" \
        -e CAPTURE_SKIP_PNG="${3:-0}" \
        -e CAPTURE_WIDTH="${CAPTURE_WIDTH}" \
        -e CAPTURE_MARGIN="${CAPTURE_MARGIN}" \
        -e CAPTURE_FONT_SCALE="${CAPTURE_FONT_SCALE}" \
        -e CAPTURE_PAGES="${CAPTURE_PAGES}" \
        -e CAPTURE_MIN_PT="${CAPTURE_MIN_PT}" \
        -e CAPTURE_HIDE="${CAPTURE_HIDE}" \
        -v "${D_PROJ}/script/capture.js":/usr/src/app/capture.js:ro \
        -v "${D_PROJ}/static":/out \
        -w /usr/src/app \
        "${IMAGE}" node capture.js
}

capture "${CAPTURE_URL}" nathan-genetzky-resume 0
# The B&W sheet is a print fallback, so skip the png and avoid a second large
# binary in the repo.
capture "${CAPTURE_URL%/}/bw/" nathan-genetzky-resume-bw 1
