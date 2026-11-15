# syntax=docker/dockerfile:1

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Pin the version so Dependabot can track base-image updates and bumps are
# explicit, reviewable PRs rather than silent upgrades.
# Python 3.15.2 fixes CVE-2026-115557 (Critical), CVE-2026-119170 (High),
# CVE-2026-87910, CVE-2026-114583, CVE-2025-15367, and CVE-2026-12345 (all
# Medium).  The 3.14 line has no released fix for CVE-2026-119170.
# CVE-2026-116566 (Medium) is fixed only in 3.16 and is suppressed in
# .grype.yaml.
FROM python:3.15.2-alpine3.24 AS builder

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Download dependencies as a separate step to take advantage of Docker's caching.
# BuildKit is required for the cache and bind mounts below.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# this layer.
# DL3042: the BuildKit cache mount at /root/.cache/pip is intentional — it
# speeds up repeated local builds by caching downloaded wheels across runs.
# --require-hashes refuses to install any package whose digest does not match
# an entry in requirements.txt, preventing supply-chain substitution attacks.
# hadolint ignore=DL3042
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install --require-hashes --no-cache-dir --prefix="/install" \
        -r requirements.txt

FROM python:3.15.2-alpine3.24

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

ENV __1121CITRUS_APP_DIR=/usr/local/1121citrus/app
ENV DEBUG=false
ENV PRETTIFY=false
ENV INDENT=2

# Consolidate OS setup into a single layer to minimise wasted bytes visible
# to dive.  Combining apk, pip removal, and adduser into one RUN prevents
# inter-layer waste that would otherwise accumulate across separate layers.
#
# Alpine 3.24 ships jq 1.8.2-r0, which resolves all previously open jq CVEs
# (CVE-2024-53427, CVE-2025-48060, CVE-2024-23337).  pip is removed because
# it is only needed in the builder stage; removing it here eliminates its CVE
# surface in the final image.
#
# zlib>=1.4-r0 fixes CVE-2026-4738 (Critical).  The explicit lower bound
# makes the build fail rather than silently ship the vulnerable base-image
# zlib when a cached `apk upgrade` layer predates the fix.
#
# Alpine 3.24 has not yet published its musl CVE-2026-107891 fix.
# Pin the patched 1.2.6-r6 packages from edge; remove this exception once
# the same versions are available in the stable 3.24 repository.
#
# sqlite-libs is removed because nothing in this image uses SQLite, and
# Alpine 3.24 has no fix for its open High/Medium CVEs.  The base image
# installs it only as a dependency of the `.python-rundeps` virtual package,
# so that package is rebuilt without libsqlite3, which lets apk remove
# sqlite-libs while keeping the package database consistent.  Python's
# sqlite3 module is deleted with it so `import sqlite3` fails cleanly.
#
# DL3018: version pinning is handled by pinning the Alpine base image minor
# version; pinning individual package versions inside apk add is redundant.
# hadolint ignore=DL3018,DL3017
ARG UID=10001
SHELL ["/bin/ash", "-o", "errexit", "-o", "pipefail", "-c"]
RUN apk upgrade --no-cache \
    && apk add --no-cache "jq=1.8.2-r0" "zlib>=1.4-r0" \
    && apk add --no-cache \
        --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
        "musl=1.2.6-r6" "musl-utils=1.2.6-r6" \
    && apk info --depends .python-rundeps \
        | grep '^so:' \
        | grep -v '^so:libsqlite3\.' \
        | xargs apk add --no-cache --virtual .python-rundeps-nosqlite \
    && apk del --no-cache .python-rundeps \
    && ! apk info --installed sqlite-libs \
    && rm -rf /usr/local/lib/python3.*/sqlite3 \
        /usr/local/lib/python3.*/lib-dynload/_sqlite3.*.so \
    && python -m pip uninstall -y pip \
    && adduser \
        --disabled-password --gecos "" --shell "/sbin/nologin" \
        --no-create-home --uid "${UID}" \
        canonicalize-json
COPY --from=builder /install /usr/local
COPY --chmod=755 ./src/canonicalize-json /usr/local/bin/

WORKDIR ${__1121CITRUS_APP_DIR}
ENV PATH=${__1121CITRUS_APP_DIR}/bin/:${PATH}

# Switch to the non-privileged user to run the application.
USER canonicalize-json

# Copy the source code into the container.
COPY --chmod=755 ./src/canonicalize_json.py .

ARG VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="canonicalize-json" \
      org.opencontainers.image.description="JCS (RFC 8785) compliant JSON formatter" \
      org.opencontainers.image.url="https://github.com/1121citrus/canonicalize-json" \
      org.opencontainers.image.source="https://github.com/1121citrus/canonicalize-json" \
      org.opencontainers.image.vendor="1121 Citrus Avenue" \
      org.opencontainers.image.authors="James Hanlon <jim@hanlonsoftware.com>" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}"

ENTRYPOINT [ "/usr/local/bin/canonicalize-json" ]
