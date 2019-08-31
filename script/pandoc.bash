#!/bin/bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="${D_SCRIPT}/../"
IMAGE="jagregory/pandoc"

pandoc(){
    cd "${D_PROJ}"
    docker run -it --rm  \
        -v  "$(pwd):/source/:ro" \
        -v  "$(pwd)/build/:/work/" \
        "${IMAGE}" \
        "$@"

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    pandoc "$@"
fi

