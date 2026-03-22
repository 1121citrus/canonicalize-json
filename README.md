# canonicalize-json

[![CI](https://github.com/1121citrus/canonicalize-json/actions/workflows/ci.yml/badge.svg)](https://github.com/1121citrus/canonicalize-json/actions/workflows/ci.yml)

A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785) compliant JSON formatter, utilizing the [Python JCS](https://pypi.org/project/jcs) library.

**What is JCS / RFC 8785?**  JSON Canonicalization Scheme (JCS) produces a
deterministic, byte-for-byte identical serialization of any JSON value: object
keys are sorted by Unicode code-point order recursively, and all unnecessary
whitespace is removed.  The resulting byte sequence is suitable for hashing,
digital signing, content-addressable storage, and reproducible diffs of JSON
stored in version control.

The main author of the [Python JCS](https://pypi.org/project/jcs) library is
[Anders Rundgren](https://github.com/cyberphone). The original source code is at
[cyberphone/json-canonicalization](https://github.com/cyberphone/json-canonicalization/tree/master/python3)
including comprehensive test data.

## Contents

- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security considerations](#security-considerations)
- [Building](#building)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Attributions and provenance](#attributions-and-provenance)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with
  [buildx](https://docs.docker.com/build/buildx/) for building images)
- Bash 4.0+ for running the test suite and build script

## Usage

`PRETTIFY` mode requires `jq` to be installed locally when running the helper
script directly outside Docker; the published container already includes it.

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

| Variable | Default | Notes |
| --- | :---: | --- |
| `DEBUG` | `false` | If `true`, enables shell `xtrace` and `verbose` options inside the entrypoint script. |
| `PRETTIFY` | `false` | If `true`, re-formats the canonical JSON with `jq` for human readability. |
| `PRETTY_PRINT` | `false` | Synonym for `PRETTIFY`. |
| `INDENT` | `2` | Indentation width for `jq --indent` when prettifying. Valid range: `0`–`7`. Values outside this range cause `jq` to exit non-zero. |

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

- **Read-only root filesystem:** For hardened deployments, run with
  `--read-only --tmpfs /tmp`.  The container writes nothing to disk at runtime,
  so a read-only rootfs is fully compatible:

  ```bash
  echo '{"b":1,"a":2}' | docker run -i --rm --read-only --tmpfs /tmp 1121citrus/canonicalize-json:latest
  ```

- **Supply-chain integrity:** Python dependencies in `requirements.txt` are
  hash-pinned (`--require-hashes`).  The base image is pinned to a specific
  Python *and* Alpine minor version (e.g. `python:3.13.7-alpine3.21`) so the
  OS package set is reproducible across builds.
- **SBOM and provenance:** Published images carry an SPDX Software Bill of
  Materials and a SLSA Build Provenance Level 3 attestation, both stored as
  OCI referrers alongside the image manifest.

## Building

BuildKit is required because the Dockerfile uses cache and bind mounts
during dependency installation (enabled automatically when using
`docker buildx`).

```bash
./build --version x.y.z
```

To build and push to Docker Hub (multi-platform `linux/amd64` + `linux/arm64`):

```bash
./build --push --version x.y.z
```

The build script will:

1. Lint the Dockerfile with [hadolint](https://github.com/hadolint/hadolint) and
   all shell scripts with [shellcheck](https://github.com/koalaman/shellcheck).
2. Build the image locally and tag it as `1121citrus/canonicalize-json:VERSION`.
   The `:latest` tag is **not** applied for development builds (when `--version`
   is not specified) to avoid overwriting a production tag in the local Docker
   daemon.
3. Run the integration test suite against the locally built image.
4. Scan with [Trivy](https://github.com/aquasecurity/trivy) — exits non-zero if
   any fixable HIGH or CRITICAL CVEs are found.
5. Optionally push a multi-platform image to Docker Hub when `--push` is given,
   including SBOM and provenance attestations.

## Testing

All tests require a built Docker image. Build first, then run:

```bash
./build
bash test/run-all-tests
```

Individual test files can also be run directly:

| Test file | What it validates |
| --- | --- |
| `test/bin/canonicalize` | Key sorting, primitives, arrays, scalars, deep nesting, Unicode key order, invalid/empty input rejection |
| `test/bin/prettify` | `PRETTIFY`/`PRETTY_PRINT` env vars, `INDENT` values 0–7, default compact output |
| `test/bin/image-structure` | Non-root user, installed binaries (`python3`, `jq`), nologin shell, `jcs` module |
| `test/bin/env-metadata` | Build-time `APP_*` env vars and OCI labels |

## CI/CD

GitHub Actions runs on every push to `main`/`master`/`staging` and on pull
requests.  The pipeline is defined in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

| Stage | What it does |
| --- | --- |
| **lint** | hadolint on Dockerfile; shellcheck on all shell scripts and tests |
| **build** | Builds the Docker image and uploads it as a workflow artifact |
| **test** | Downloads the artifact and runs `test/run-all-tests` |
| **scan** | Trivy vulnerability scan — fails on fixable HIGH/CRITICAL CVEs |
| **push** | Multi-platform build + push to Docker Hub (version tags, `main`/`master`, and `staging` only) |

### Required repository secrets

| Secret | Description |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/) |

### Tagging strategy

| Trigger | Image tag(s) |
| --- | --- |
| Push to `main` / `master` | `:edge` |
| Push to `staging` | `:staging-YYYY.MM.DD.HHMMSS`, `:staging` |
| Version tag `v1.2.3` | `:1.2.3`, `:latest` |

## Attributions and provenance

| Component | Author / Source | License |
| --- | --- | --- |
| `canonicalize-json` (this project) | [Jim Hanlon](https://github.com/1121citrus) | AGPL-3.0-or-later |
| [jcs](https://pypi.org/project/jcs) Python library | [Anders Rundgren](https://github.com/cyberphone) / [cyberphone/json-canonicalization](https://github.com/cyberphone/json-canonicalization) | Apache-2.0 |
| [RFC 8785](https://datatracker.ietf.org/doc/html/rfc8785) specification | IETF | — |
| [Python](https://python.org) runtime | Python Software Foundation | PSF |
| [jq](https://jqlang.github.io/jq/) | Stephen Dolan et al. | MIT |
| [Alpine Linux](https://alpinelinux.org) base image | Alpine Linux Team | Various (GPL-compatible) |

Build provenance and an SPDX SBOM are attached to every published image as OCI
referrers.  To inspect them:

```bash
# View the SBOM
docker buildx imagetools inspect 1121citrus/canonicalize-json:latest \
    --format '{{ json .SBOM.SPDX }}'

# View the provenance attestation
docker buildx imagetools inspect 1121citrus/canonicalize-json:latest \
    --format '{{ json .Provenance.SLSA }}'
```
