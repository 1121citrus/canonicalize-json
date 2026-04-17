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
FROM python:3.13.7-alpine3.22 AS builder

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

FROM python:3.13.7-alpine3.22

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

ENV __1121CITRUS_APP_DIR=/usr/local/1121citrus/app
ENV DEBUG=false
ENV PRETTIFY=false
ENV INDENT=2

# Apply all available security patches from the Alpine repository before
# adding application packages.  Alpine 3.22 ships jq 1.8.1 which resolves
# all previously open jq CVEs (CVE-2024-53427, CVE-2025-48060, CVE-2024-23337).
# DL3018: version pinning is handled by pinning the Alpine base image minor
# version; pinning individual package versions inside apk add is redundant.
# hadolint ignore=DL3018,DL3017
RUN apk upgrade --no-cache \
    && apk add --no-cache "jq=1.8.1-r0"
COPY --from=builder /install /usr/local
COPY --chmod=755 ./src/canonicalize-json /usr/local/bin/

WORKDIR ${__1121CITRUS_APP_DIR}
ENV PATH=${__1121CITRUS_APP_DIR}/bin/:${PATH}

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
        --disabled-password --gecos "" --shell "/sbin/nologin" \
        --no-create-home --uid "${UID}" \
        canonicalize-json

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
