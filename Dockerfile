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

# Pin the Python *and* Alpine minor versions together so the OS package set is
# fully reproducible across builds.  Bumping either component is a deliberate,
# reviewable change rather than a silent background upgrade.
ARG PYTHON_VERSION=3.13.7
ARG ALPINE_VERSION=3.21
FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

ARG AUTHORS='Jim Hanlon «jim@hanlonsoftware.com»'
ARG BUILD_DATE=unknown
ARG GIT_COMMIT=unknown
ARG LICENSE=AGPL-3.0-or-later
ARG VERSION=dev

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

ENV __1121CITRUS_APP_DIR=/usr/local/1121citrus/app
ENV DEBUG=false
ENV PRETTIFY=false
ENV INDENT=2

# Embed build metadata in env vars for runtime access.
ENV \
    APP_AUTHORS="${AUTHORS}" \
    APP_BUILD_DATE="${BUILD_DATE}" \
    APP_COMMIT="${GIT_COMMIT}" \
    APP_LICENSE="${LICENSE}" \
    APP_VERSION="${VERSION}"

# OCI standard labels
LABEL org.opencontainers.image.authors="${AUTHORS}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.documentation="https://github.com/1121citrus/canonicalize-json"
LABEL org.opencontainers.image.licenses="${LICENSE}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL org.opencontainers.image.source="https://github.com/1121citrus/canonicalize-json"
LABEL org.opencontainers.image.title="canonicalize-json"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/1121citrus/canonicalize-json"
LABEL org.opencontainers.image.vendor="1121 Citrus, LTD"
LABEL org.opencontainers.image.version="${VERSION}"

# DL3018: apk package version pinning is handled by pinning the Alpine *base
# image* minor version (alpine3.21 above).  Pinning individual package versions
# inside apk add would require tracking apk version strings separately and
# provides no additional reproducibility guarantee beyond what the base image
# already gives us.
# hadolint ignore=DL3018
RUN apk add --no-cache --upgrade jq \
    && python -m pip install --no-cache-dir --upgrade "pip==26.0.1"
COPY --chmod=755 ./src/canonicalize-json /usr/local/bin/

WORKDIR ${__1121CITRUS_APP_DIR}

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
        --disabled-password --gecos "" --shell "/sbin/nologin" \
        --no-create-home --uid "${UID}" \
        canonicalize-json

# Download dependencies as a separate step to take advantage of Docker's caching.
# BuildKit is required for the cache and bind mounts below.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# this layer.
# --require-hashes refuses to install any package whose digest does not match
# an entry in requirements.txt, preventing supply-chain substitution attacks.
# The cache mount is scoped to root's pip cache; the bind mount avoids copying
# the requirements file into the image layer.
# DL3042: the BuildKit cache mount at /root/.cache/pip is intentional — it
# speeds up repeated local builds by caching downloaded wheels across runs.
# The --require-hashes flag ensures only the exact digests in requirements.txt
# are accepted, so the cache cannot introduce untrusted packages.
# hadolint ignore=DL3042
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install --require-hashes -r requirements.txt

# Switch to the non-privileged user to run the application.
USER canonicalize-json

# Copy the source code into the container.
COPY --chmod=755 ./src/canonicalize_json.py .

ENTRYPOINT [ "/usr/local/bin/canonicalize-json" ]

