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

ARG PYTHON_VERSION=3.13.7
FROM python:${PYTHON_VERSION}-alpine

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

ENV __1121CITRUS_APP_DIR=/usr/local/1121citrus/app
ENV DEBUG=false
ENV PRETTIFY=false
ENV INDENT=2

RUN APK_PACKAGES="jq" \
    && apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache "${APK_PACKAGES}" \
    && python -m pip install --upgrade "pip>=26" \
    && true
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

# Download dependencies as a separate step to take advantage of Docker's caching.
# BuildKit is required for the cache and bind mounts below.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# this layer.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt

# Switch to the non-privileged user to run the application.
USER canonicalize-json

# Copy the source code into the container.
COPY --chmod=755 ./src/canonicalize_json.py .

ENTRYPOINT [ "/usr/local/bin/canonicalize-json" ]

