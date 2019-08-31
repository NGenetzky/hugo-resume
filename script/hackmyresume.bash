#!/bin/bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="${D_SCRIPT}/../"
# IMAGE="hackmyresume"
IMAGE="kir4h/hackmyresume-all-themes:latest"

hackmyresume(){
    cd "${D_PROJ}"
    docker run -it --rm  \
        --user "$(id -u)" \
        -v  "$(pwd)/data:/in/:ro" \
        -v  "$(pwd)/static/resumes/:/resumes/" \
        "${IMAGE}" \
        "$@"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    hackmyresume "$@"
fi

