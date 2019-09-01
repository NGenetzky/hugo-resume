#!/bin/bash

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="${D_SCRIPT}/../"

DEFAULT_MD="${D_PROJ}/content/post/nathan-genetzky-resume.md"
DEFAULT_DOCX="${D_PROJ}/static/nathan-genetzky-resume.docx"

build_docx(){
    local i_file o_file
    i_file="${1-${DEFAULT_MD}}" # md prefered
    o_file_docx="${DEFAULT_DOCX}"
    o_file_pdf="${o_file_docx}.pdf"

    cd "${D_PROJ}"
    pandoc -s "${i_file}" -o "${o_file_docx}"
    pandoc -s "${o_file_docx}" -o "${o_file_pdf}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    build_docx "$@"
fi

