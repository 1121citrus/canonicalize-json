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

ARG PYTHON_VERSION=3.12.10
ARG ALPINE_VERSION=3.21
ARG AWSCLI_VERSION=2.26.5

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

ARG ALPINE_VERSION
ENV ALPINE_VERSION=${ALPINE_VERSION}

ENV DEBUG=false
ENV PRETTIFY=false

RUN echo [INFO] install jq ... \
    && apk add --no-cache jq \
    && echo [INFO] install JCS - JSON Canonicalization python library ... \
    && pip install jcs

COPY --chmod=755 ./src/canonicalize-json ./src/canonicalize-json.py /usr/local/bin/

WORKDIR /
ENTRYPOINT [ "/bin/sh", "-c" ]
CMD [ "/usr/local/bin/canonicalize-json" ]

