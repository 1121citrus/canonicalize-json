# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Security

- `requirements.txt`: added SHA-256 hash pins for `jcs==0.2.1` (both wheel
  and sdist).  `pip install --require-hashes` is now enforced in the
  Dockerfile, preventing supply-chain substitution attacks.
- `Dockerfile`: pinned the Alpine minor version (`alpine3.21`) so the OS
  package set is fully reproducible across builds.
- `test/bin/image-structure`: validated `__1121CITRUS_APP_DIR` against a
  safe-character allowlist before interpolating it into a shell command,
  closing a potential shell-injection vector.
- `ci.yml`: removed the unnecessary `id-token: write` permission from the
  `push` job (Docker Hub auth uses secrets, not OIDC).

### Changed

- `build`: `--tag IMAGE:latest` is no longer applied when `VERSION=dev`
  (the default) to prevent development builds from silently shadowing a
  production `:latest` tag in the local Docker daemon.
- `ci.yml`: the build stage no longer tags the image `:latest`; that tag is
  reserved for the push stage and only applied on version tags (`vX.Y.Z`).
- `ci.yml`: Trivy `exit-code` changed from `0` to `1` (scan now blocks the
  pipeline on fixable vulnerabilities); `ignore-unfixed: true` added to
  suppress unactionable noise.
- `build`: Trivy run now passes `--exit-code 1` and `--ignore-unfixed` for
  consistency with CI; Docker socket mount is now read-only (`:ro`).
- `src/canonicalize_json.py`: `__version__` now reads from the `APP_VERSION`
  environment variable (injected at build time) rather than a hardcoded
  `'0.1'` literal.
- `src/canonicalize_json.py`: narrowed bare `except Exception` to
  `except (TypeError, ValueError)` with an explanatory comment.
- Copyright year ranges updated to `2025–2026` across all source files.
- `test/bin/canonicalize`, `test/bin/prettify`: added `set -euo pipefail`,
  copyright/SPDX headers, and a `_run` helper to reduce repetition.

### Added

- `test/bin/canonicalize`: seven new test cases — empty object `{}`, empty
  array `[]`, top-level string scalar, top-level number scalar, deeply nested
  recursive sorting, Unicode code-point key ordering, and empty-input
  rejection.
- `test/bin/prettify`: three new test cases — `INDENT=0`, `INDENT=7`
  (boundary), and a default-compact (no-prettify) guard.
- `CONTRIBUTING.md`: contributor guidelines, dependency-bump instructions,
  and coding conventions.
- `CHANGELOG.md`: this file.
- `.github/dependabot.yml`: automated weekly PRs for GitHub Actions and pip
  dependency updates.
- `README.md`: corrected `--tmpdir` → `--tmpfs` in the hardening example;
  added Attributions and Provenance table; added SBOM/provenance inspection
  commands; documented the `--require-hashes` supply-chain hardening.

### Fixed

- `README.md`: `--read-only --tmpdir /tmp` was incorrect Docker syntax;
  corrected to `--read-only --tmpfs /tmp`.

### Removed

- `.gitignore`: removed a duplicated block of Python ignore patterns that
  was present twice in the file.
- `.project`: removed the committed Eclipse IDE project file (it was already
  listed in `.gitignore` but had been tracked before the rule was added).
- `bin/`: removed the empty committed directory.

---

## [0.1.0] — Initial release

### Added

- Containerized JCS (RFC 8785) JSON canonicalization via the Python `jcs`
  library.
- `PRETTIFY` / `PRETTY_PRINT` env vars to re-format canonical output with
  `jq`.
- `INDENT` env var (default `2`) for configurable indentation depth.
- `DEBUG` env var to enable shell `xtrace`/`verbose` inside the entrypoint.
- Non-root container user (`canonicalize-json`, UID 10001).
- OCI standard labels (`org.opencontainers.image.*`) and `APP_*` runtime
  env vars embedding build metadata.
- Multi-platform image support (`linux/amd64`, `linux/arm64`).
- SBOM and SLSA provenance attestations on published images.
- GitHub Actions CI/CD pipeline (lint → build → test + scan → push).
- `build` script with hadolint, Trivy, and optional Docker Scout scanning.
- Integration test suite (`test/bin/canonicalize`, `test/bin/prettify`,
  `test/bin/image-structure`, `test/bin/env-metadata`).
