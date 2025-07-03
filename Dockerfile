# syntax=docker/dockerfile:1

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

