#!/bin/bash
# Pinned Hugo toolchain. Source this; every other script and CI job runs Hugo
# through it so local builds and CI builds cannot drift apart.
#
# 0.111.3 is the newest release this site builds on unmodified. Raising it means
# fixing two things first: 0.120 removed the _internal/google_analytics_async.html
# template that layouts/partials/head.html calls, and config.toml still spells
# disableKinds as "taxonomyTerm" (renamed to "taxonomy" in 0.73, warns from 0.116).
# 0.123 also dropped symlink support, which rules out locked git-annex files.
#
# Set HUGO=hugo to use a local install instead of the pinned image.

HUGO_VERSION="${HUGO_VERSION:-0.111.3}"
HUGO_IMAGE="${HUGO_IMAGE:-hugomods/hugo:exts-${HUGO_VERSION}}"
HUGO_PORT="${HUGO_PORT:-1313}"
HUGO_CONTAINER="${HUGO_CONTAINER:-hugo-resume-server}"

D_HUGO_SCRIPT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
D_HUGO_PROJ="$(CDPATH='' cd -- "${D_HUGO_SCRIPT}/.." && pwd -P)"

# Extra `docker run` options, e.g. HUGO_DOCKER_OPTS=(-p 1313:1313) to publish the server.
if [[ -z "${HUGO_DOCKER_OPTS+x}" ]]; then
    HUGO_DOCKER_OPTS=()
fi

hugo_run(){
    if [[ -n "${HUGO:-}" ]]; then
        (cd "${D_HUGO_PROJ}" && "${HUGO}" "$@")
    else
        docker run --rm -u "$(id -u):$(id -g)" \
            ${HUGO_DOCKER_OPTS[@]+"${HUGO_DOCKER_OPTS[@]}"} \
            -v "${D_HUGO_PROJ}":/src -w /src "${HUGO_IMAGE}" hugo "$@"
    fi
}

hugo_serve_start(){
    hugo_serve_stop
    docker run --rm --detach --name "${HUGO_CONTAINER}" \
        -u "$(id -u):$(id -g)" \
        -v "${D_HUGO_PROJ}":/src -w /src \
        -p "${HUGO_PORT}:${HUGO_PORT}" \
        "${HUGO_IMAGE}" hugo server --bind 0.0.0.0 --port "${HUGO_PORT}" >/dev/null
}

hugo_serve_stop(){
    if docker rm -f "${HUGO_CONTAINER}" >/dev/null 2>&1; then
        return 0
    fi
    # Snap-packaged dockerd can refuse to signal a container ("could not kill
    # container: permission denied"). The server runs as the invoking user, so
    # signal its host pid directly; --rm then reaps the container.
    local pid
    pid="$(docker inspect -f '{{.State.Pid}}' "${HUGO_CONTAINER}" 2>/dev/null || true)"
    if [[ -n "${pid}" && "${pid}" != "0" ]]; then
        kill -TERM "${pid}" 2>/dev/null || true
    fi
    # --rm reaps asynchronously; a restart before then collides on the name.
    for _ in $(seq 1 20); do
        docker inspect "${HUGO_CONTAINER}" >/dev/null 2>&1 || return 0
        sleep 0.5
    done
    echo "warning: container ${HUGO_CONTAINER} is still present after stop" >&2
}

hugo_serve_wait(){
    local url="http://localhost:${HUGO_PORT}/"
    for _ in $(seq 1 60); do
        if curl -fsS -o /dev/null --max-time 2 "${url}" 2>/dev/null; then
            return 0
        fi
        sleep 1
    done
    echo "error: hugo server did not answer at ${url} within 60s" >&2
    docker logs "${HUGO_CONTAINER}" 2>&1 | tail -20 >&2 || true
    hugo_diagnose_mount
    return 1
}

# An unreadable bind mount looks like an empty directory rather than an error,
# so the server starts, finds no site and exits. Snap-packaged docker only
# bind-mounts paths under $HOME, which is the usual way to hit this.
hugo_diagnose_mount(){
    if ! docker run --rm -v "${D_HUGO_PROJ}":/src "${HUGO_IMAGE}" \
            test -f /src/config/_default/config.toml >/dev/null 2>&1; then
        echo "hint: docker cannot see ${D_HUGO_PROJ}; the bind mount is empty." >&2
        echo "      snap-packaged docker only bind-mounts paths under \$HOME." >&2
    fi
}
