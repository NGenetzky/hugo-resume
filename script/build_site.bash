#!/bin/bash
# Build the publishable site into public/ using the pinned Hugo.
#
# Verifies the binaries both before and after the build, because `hugo` copies
# static/ verbatim and exits 0 on pointer files or stubs. Checking the output is
# what actually guarantees the deploy is not silently broken.
#
# Override the output directory with SITE_DEST.

D_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"

# shellcheck source=script/hugo.bash
source "${D_SCRIPT}/hugo.bash"

SITE_DEST="${SITE_DEST:-public}"

build_site(){
    "${D_SCRIPT}/check_artifacts.bash"
    hugo_run --cleanDestinationDir --destination "${SITE_DEST}" "$@"
    "${D_SCRIPT}/check_artifacts.bash" "${D_HUGO_PROJ}/${SITE_DEST}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Bash Strict Mode
    set -eu -o pipefail

    build_site "$@"
fi
