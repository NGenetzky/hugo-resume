#!/bin/bash
# Serve the site at http://localhost:1313/ using the pinned Hugo.
#
# script/build_capture.bash captures its artifacts from this server, so run it
# in another terminal first:
#   script/serve.bash
#   script/build_capture.bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

# shellcheck source=script/hugo.bash
source "${D_SCRIPT}/hugo.bash"

serve(){
    HUGO_DOCKER_OPTS=(-p "${HUGO_PORT}:${HUGO_PORT}")
    hugo_run server --bind 0.0.0.0 --port "${HUGO_PORT}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    serve "$@"
fi
