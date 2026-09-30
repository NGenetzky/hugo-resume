#!/bin/bash
# Fail loudly if any published binary is missing, truncated, or a placeholder.
#
# A bare `hugo` build copies static/ verbatim and exits 0 even when a file is a
# git-annex pointer, a git-lfs pointer or a zero-byte stub, so without this check
# a broken resume deploys silently and the deploy is still reported green.
#
# Usage: script/check_artifacts.bash [dir]
#   dir defaults to static/. Pass public/ to check a built site, where the same
#   files appear at the same relative paths.
#   DOCX_MIN_PT / DOCX_MAX_PAGES bound the ATS copy's body size and length.

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
D_PROJ="$(CDPATH='' cd -- "${D_SCRIPT}/.." && pwd -P)"

# path relative to the static root : expected leading magic bytes (hex) : minimum plausible size
ARTIFACTS=(
    "nathan-genetzky-resume.pdf:25504446:20000"
    "nathan-genetzky-resume-bw.pdf:25504446:20000"
    "nathan-genetzky-resume.docx.pdf:25504446:20000"
    "nathan-genetzky-resume.docx:504b0304:5000"
    "nathan-genetzky-resume.png:89504e47:50000"
    "assets/images/portrait.png:89504e47:2000"
    "apple-touch-icon.png:89504e47:1000"
    "android-chrome-192x192.png:89504e47:1000"
    "android-chrome-512x512.png:89504e47:1000"
    "favicon-16x16.png:89504e47:200"
    "favicon-32x32.png:89504e47:200"
    "favicon.ico:00000100:500"
)

magic_of(){
    od -An -tx1 -N4 -- "$1" | tr -d ' \n'
}

# Report the common placeholder formats by name; "bad magic" alone is a bad hint.
placeholder_kind(){
    local head
    head="$(head -c 64 -- "$1" 2>/dev/null | tr -d '\0')"
    case "${head}" in
        /annex/objects/*|annex/objects/*) echo "a git-annex pointer (run: datalad get / git annex get)" ;;
        "version https://git-lfs"*)       echo "a git-lfs pointer (run: git lfs pull)" ;;
        *)                                echo "" ;;
    esac
}

check_artifacts(){
    local root entry path want_magic min_size size got_magic kind rc
    root="${1-${D_PROJ}/static}"
    rc=0

    echo "checking artifacts in ${root}"
    for entry in "${ARTIFACTS[@]}"; do
        IFS=: read -r path want_magic min_size <<<"${entry}"
        local f="${root}/${path}"

        # Checked before -f, which follows the link and would otherwise report a
        # valid-looking file. Hugo cannot follow symlinks under static/, so a
        # locked git-annex file passes every other check and still breaks the build.
        if [[ -L "${f}" ]]; then
            echo "SYMLINK  ${path} is a symlink; annexed files must be unlocked" >&2
            echo "         (git annex config --set annex.addunlocked true, then git annex unlock)" >&2
            rc=1
            continue
        fi

        if [[ ! -f "${f}" ]]; then
            echo "MISSING  ${path}" >&2
            rc=1
            continue
        fi

        kind="$(placeholder_kind "${f}")"
        if [[ -n "${kind}" ]]; then
            echo "STUB     ${path} is ${kind}" >&2
            rc=1
            continue
        fi

        size="$(stat -c %s -- "${f}")"
        if (( size < min_size )); then
            echo "TRUNCATED ${path} is ${size}B, expected at least ${min_size}B" >&2
            rc=1
            continue
        fi

        got_magic="$(magic_of "${f}")"
        if [[ "${got_magic}" != "${want_magic}" ]]; then
            echo "CORRUPT  ${path} starts with ${got_magic}, expected ${want_magic}" >&2
            rc=1
            continue
        fi

        printf 'ok       %s (%sB)\n' "${path}" "${size}"
    done

    # Only meaningful once the files are known to be real documents.
    if (( rc == 0 )); then
        python3 "${D_SCRIPT}/check_docx_fonts.py" \
            "${root}/nathan-genetzky-resume.docx" \
            "${root}/nathan-genetzky-resume.docx.pdf" \
            "${DOCX_MIN_PT:-10}" "${DOCX_MAX_PAGES:-2}" || rc=1
    fi

    if (( rc != 0 )); then
        echo "error: published artifacts are not deployable" >&2
    fi
    return "${rc}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    check_artifacts "$@"
fi
