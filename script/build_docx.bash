#!/bin/bash
# Build static/nathan-genetzky-resume.docx and .docx.pdf from the markdown post.
#
# Runs pandoc in Docker (pandoc/extra, which ships the enumitem and titlesec
# packages the tight layout needs) so output does not depend on whatever TeX
# Live is installed locally. Set PANDOC=pandoc to use a local install instead.
#
# Tunables: DOCX_MARGIN (inches), DOCX_FONTSIZE (10pt/11pt/12pt),
# DOCX_TWOCOLUMN=1, PANDOC_IMAGE.
#
# On DOCX_TWOCOLUMN: a two-column pdf extracts to garbled text, because
# pdftotext and most applicant tracking systems interleave the columns line by
# line. Leave it off unless the pdf is only ever read by a human.

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="$(CDPATH='' cd -- "${D_SCRIPT}/.." && pwd -P)"

DEFAULT_MD="content/post/nathan-genetzky-resume.md"
DEFAULT_DOCX="static/nathan-genetzky-resume.docx"

DOCX_MARGIN="${DOCX_MARGIN:-0.75}"
DOCX_FONTSIZE="${DOCX_FONTSIZE:-10pt}"
DOCX_TWOCOLUMN="${DOCX_TWOCOLUMN:-0}"
PANDOC_IMAGE="${PANDOC_IMAGE:-pandoc/extra:3.1}"

pandoc_run(){
    if [[ -n "${PANDOC:-}" ]]; then
        "${PANDOC}" "$@"
    else
        docker run --rm -u "$(id -u):$(id -g)" \
            -v "${D_PROJ}":/data -w /data "${PANDOC_IMAGE}" "$@"
    fi
}

build_docx(){
    local i_file o_file_docx o_file_pdf
    local -a latex_opts
    i_file="${1-${DEFAULT_MD}}" # md preferred
    o_file_docx="${DEFAULT_DOCX}"
    o_file_pdf="${o_file_docx}.pdf"

    cd "${D_PROJ}"

    # Word defaults to 1in margins and pandoc cannot override them from the
    # command line, so patch the geometry into a copy of its reference document.
    pandoc_run --print-default-data-file reference.docx > .reference-base.docx
    python3 "${D_SCRIPT}/make_reference_docx.py" \
        .reference-base.docx .reference.docx "${DOCX_MARGIN}" >/dev/null

    latex_opts=(
        -V "geometry:margin=${DOCX_MARGIN}in"
        -V "fontsize=${DOCX_FONTSIZE}"
        -H "script/resume-tight.tex"
    )
    if [[ "${DOCX_TWOCOLUMN}" == "1" ]]; then
        latex_opts+=(-V classoption=twocolumn)
    fi

    pandoc_run -s "${i_file}" --reference-doc=.reference.docx -o "${o_file_docx}"
    pandoc_run -s "${o_file_docx}" "${latex_opts[@]}" -o "${o_file_pdf}"

    rm -f .reference-base.docx .reference.docx
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    # set -x
    build_docx "$@"
fi

