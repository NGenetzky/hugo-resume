#!/bin/bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="${D_SCRIPT}/../"

setup(){
  cd "${D_PROJ}"
    docker build -t 'hackmyresume' ./
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    setup "$@"
fi

