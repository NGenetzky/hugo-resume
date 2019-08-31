#!/bin/bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="${D_SCRIPT}/../"
source "${D_SCRIPT}/hackmyresume.bash"

hackmyresume_build_all(){
    local d_resume
    d_resume="$(pwd)/static/resumes/"
    cd "${D_PROJ}"
    install -d "${d_resume}"
    cp -T \
        "${D_PROJ}/data/nathan-genetzky-cv.fresh.json" \
        "${d_resume}/resume.json"
    docker run -it \
        --user "$(id -u)" \
        --rm --name=hackmyresume \
        -v  "${d_resume}:/resumes/" \
        kir4h/hackmyresume-all-themes \
        build_all_themes.sh \
        'nathan-genetzky'
}

hackmyresume_build(){
    hackmyresume \
        build '/in/nathan-genetzky-cv.fresh.json'
        to '/out/resume.all'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    hackmyresume_build_all "$@"
    # hackmyresume_build "$@"
fi

