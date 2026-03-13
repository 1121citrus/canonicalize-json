# canonicalize-json

[![CI](https://github.com/1121citrus/canonicalize-json/actions/workflows/ci.yml/badge.svg)](https://github.com/1121citrus/canonicalize-json/actions/workflows/ci.yml)

A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785) compliant JSON formatter, utilizing the [Python JCS](https://pypi.org/project/jcs) library.

The main author of the [Python JCS](https://pypi.org/project/jcs) library is
[Anders Rundgren](https://github.com/cyberphone). The original source code is at [cyberphone/json-canonicalization](https://github.com/cyberphone/json-canonicalization/tree/master/python3) including comprehensive test data.

## Contents

- [Contents](#contents)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security considerations](#security-considerations)
- [Building](#building)
- [Testing](#testing)
- [CI/CD](#cicd)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with
  [buildx](https://docs.docker.com/build/buildx/) for building images)
- Bash 4.0+ for running the test suite and build script

## Usage

`PRETTIFY` mode requires `jq` to be installed locally when running the helper script directly; the published container already includes it.

### Ordinary canonicalization

```sh
$ cat json | \
> tee >(sed 's/^/BEFORE: /' >/dev/stderr) | \
> docker run -i --rm 1121citrus/canonicalize-json:latest | \
> sed 's/^/AFTER: /'
BEFORE: {"z":{"o":"172","d":"122","h":"7A"},"1":{"h":"31","o":"61","d":"49"}}
AFTER: {"1":{"d":"49","h":"31","o":"61"},"z":{"d":"122","h":"7A","o":"172"}}
```

### Prettified canonicalization

```sh
$ cat json | \
> tee >(jq . | sed 's/^/BEFORE: /' >/dev/stderr) | \
> docker run -i --rm -e PRETTIFY=true 1121citrus/canonicalize-json:latest | \
> sed 's/^/AFTER: /'
BEFORE: {
BEFORE:   "z": {
BEFORE:     "o": "172",
BEFORE:     "d": "122",
BEFORE:     "h": "7A"
BEFORE:   },
BEFORE:   "1": {
BEFORE:     "h": "31",
BEFORE:     "o": "61",
BEFORE:     "d": "49"
BEFORE:   }
BEFORE: }
AFTER: {
AFTER:   "1": {
AFTER:     "d": "49",
AFTER:     "h": "31",
AFTER:     "o": "61"
AFTER:   },
AFTER:   "z": {
AFTER:     "d": "122",
AFTER:     "h": "7A",
AFTER:     "o": "172"
AFTER:   }
AFTER: }
```

## Configuration

| Variable       | Default | Notes                                                                                     |
| -------------- | :-----: | ----------------------------------------------------------------------------------------- |
| `DEBUG`        | `false` | If `true` then the shell script will enable options `xtrace` and `verbose`                  |
| `PRETTIFY`     | `false` | If `true` then the usual whitespace is inserted into the canonical JSON to make it pretty. |
| `PRETTY_PRINT` | `false` | Synonym for `PRETTIFY`.                                                                     |
| `INDENT`       |   `2`   | When prettifying, pass this indent value to `jq --indent`. Valid range: `0`–`7`.            |

## Security considerations

- **No secrets required:** This tool processes JSON via stdin/stdout and
  requires no authentication credentials or API keys.
- **Non-root execution:** The container runs as a non-privileged user
  (`canonicalize-json`, UID 10001).
- **No network access needed:** The container does not make network
  calls at runtime. Add `--network=none` for full isolation:
  ```bash
  echo '{"b":1,"a":2}' | docker run -i --rm --network=none 1121citrus/canonicalize-json:latest
  ```
- **Read-only rootfs:** For hardened deployments, run with
  `--read-only --tmpdir /tmp`.

## Building

BuildKit is required because the Dockerfile uses cache and bind mounts
during dependency installation (enabled automatically when using
`docker buildx`).

```bash
VERSION=x.y.z ./build
```

To build and push to Docker Hub (multi-platform `linux/amd64` + `linux/arm64`):

```bash
VERSION=x.y.z PUSH=true ./build
```

The build script will:

1. Lint the Dockerfile with [hadolint](https://github.com/hadolint/hadolint)
2. Build the image locally and tag as `1121citrus/canonicalize-json:VERSION`
   and `canonicalize-json`
3. Scan with [Trivy](https://github.com/aquasecurity/trivy) and
   [Docker Scout](https://docs.docker.com/scout/) (if available) for
   vulnerabilities
4. Optionally push a multi-platform image to Docker Hub when `PUSH=true`

## Testing

All tests require a built Docker image. Build first, then run:

```bash
./build
bash test/run-all-tests
```

Individual test files can also be run directly:

| Test file | What it validates |
| --- | --- |
| `test/bin/canonicalize` | Key sorting, primitive/array handling, invalid JSON rejection |
| `test/bin/prettify` | `PRETTIFY`/`PRETTY_PRINT` env vars, custom indent values |
| `test/bin/image-structure` | Non-root user, installed binaries (`python3`, `jq`), nologin shell, `jcs` module |
| `test/bin/env-metadata` | Build-time `APP_*` env vars and OCI labels |

## CI/CD

GitHub Actions runs on every push to `main`/`master`/`staging` and on
pull requests. The pipeline is defined in `.github/workflows/ci.yml`.

| Stage | What it does |
| --- | --- |
| **lint** | hadolint on Dockerfile, shellcheck on all shell scripts and tests |
| **build** | Builds the Docker image and uploads it as an artifact |
| **test** | Downloads the artifact and runs `test/run-all-tests` |
| **scan** | Trivy vulnerability scan at all severity levels |
| **push** | Multi-platform build + push to Docker Hub (tags, `main`/`master`, and `staging` only) |

### Required repository secrets

| Secret | Description |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/) |

### Tagging strategy

- Pushes to `main`/`master`: tagged as `edge`
- Pushes to `staging`: tagged as `staging-YYYY.MM.DD.HHMMSS` and `staging`
- Version tags (`v1.2.3`): tagged as `1.2.3` and `latest`
