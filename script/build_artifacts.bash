#!/bin/bash
# Regenerate every published resume artifact, then verify it is deployable.
#
# This is the whole artifact pipeline in one command, used by CI and usable by
# hand. It owns the Hugo server lifecycle because build_capture.bash captures
# from a live site rather than from the built output.
#
#   script/build_artifacts.bash
#
# Outputs (all under static/): nathan-genetzky-resume.{png,pdf,docx,docx.pdf}
# and nathan-genetzky-resume-bw.pdf.

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

# shellcheck source=script/hugo.bash
source "${D_SCRIPT}/hugo.bash"

build_artifacts(){
    trap hugo_serve_stop EXIT

    hugo_serve_start
    hugo_serve_wait

    "${D_SCRIPT}/build_capture.bash"
    "${D_SCRIPT}/build_docx.bash"

    hugo_serve_stop
    trap - EXIT

    "${D_SCRIPT}/check_artifacts.bash"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    build_artifacts "$@"
fi
