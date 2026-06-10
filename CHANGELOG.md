# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

## [1.1.6] - 2026-06-10

### Security

- `Dockerfile`: bumped base image from `python:3.14.1-alpine3.22` to
  `python:3.14.5-alpine3.22`, resolving CVE-2025-13462 (Critical),
  CVE-2026-4224 (High), and CVE-2026-3644 (High).
- `.grype.yaml`: suppress CVE-2026-7210 (Critical) for the Python binary;
  no stable 3.14.x fix available — only addressed in the 3.15.0b2
  pre-release.  Remove when a 3.14.x patch ships.

### Changed

- `build`: added advisory stages 5f (metrics via scc) and 5g (security via
  graudit); pinned `SCC_IMAGE` to `v3.7.0`.

## [1.1.5] - 2026-05-03

### Security

- `requirements.txt`: added SHA-256 hash pins for `jcs==0.2.1` (both wheel
  and sdist).  `pip install --require-hashes` is now enforced in the
  Dockerfile, preventing supply-chain substitution attacks.
- `Dockerfile`: pinned the Alpine minor version (`alpine3.22`) so the OS
  package set is fully reproducible across builds.
- `test/bin/image-structure`: validated `__1121CITRUS_APP_DIR` against a
  safe-character allowlist before interpolating it into a shell command,
  closing a potential shell-injection vector.
- `ci.yml`: removed the unnecessary `id-token: write` permission from the
  `push` job (Docker Hub auth uses secrets, not OIDC).
- `.grype.yaml`: suppress CVE-2026-6100 (Critical), CVE-2026-3298 (High),
  and CVE-2026-4786 (High) for the Python 3.14.1 binary; no upstream fix
  available for any of the three as of 2026-05-04.
- `.grype.yaml`: fix package name `sqlite` → `sqlite-libs` so
  CVE-2025-70873 (High) is correctly matched and suppressed.
- `.grype.yaml`: add CVE-2025-60876 (Medium) for `busybox`/`busybox-binsh`/
  `ssl_client`; no fix in Alpine 3.22 yet.
- `SECURITY.md`: document all unfixable Python and Alpine CVEs; correct base
  image reference to `python:3.14.x-alpine3.22`; update scan date to
  2026-05-04.

### Fixed

- `README.md`: suppress false-positive `generic-api-key` secret detection in
  CI scans.
- `README.md`: `--read-only --tmpdir /tmp` was incorrect Docker syntax;
  corrected to `--read-only --tmpfs /tmp`.

### Changed

- `ci.yml`: updated `trivy-action` from `0.35.0` to `v0.36.0` (ships Trivy
  v0.70.0).
- `build`: regenerate scripts with Gitleaks advisement support and tool
  version bumps (Grype v0.87.0→v0.112.0, Hadolint v2.12.0→v2.14.0,
  Shellcheck v0.10.0→v0.11.0, Trivy 0.62.1→0.70.0).
- `build`: dive output filtered to suppress unchanged-layer noise.
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

- `.github/workflows/gitleaks-ci.yml`: Gitleaks secrets scan workflow.
- `.github/dependabot.yml`: automated weekly PRs for GitHub Actions, Docker,
  and pip dependency updates; pre-release Python versions (alpha, beta, RC)
  excluded from Docker ecosystem updates.
- `test/bin/canonicalize`: seven new test cases — empty object `{}`, empty
  array `[]`, top-level string scalar, top-level number scalar, deeply nested
  recursive sorting, Unicode code-point key ordering, and empty-input
  rejection.
- `test/bin/prettify`: three new test cases — `INDENT=0`, `INDENT=7`
  (boundary), and a default-compact (no-prettify) guard.
- `CONTRIBUTING.md`: contributor guidelines, dependency-bump instructions,
  and coding conventions.
- `CHANGELOG.md`: this file.
- `README.md`: corrected `--tmpdir` → `--tmpfs` in the hardening example;
  added Attributions and Provenance table; added SBOM/provenance inspection
  commands; documented the `--require-hashes` supply-chain hardening.

### Removed

- `.gitignore`: removed a duplicated block of Python ignore patterns that
  was present twice in the file.
- `.project`: removed the committed Eclipse IDE project file (it was already
  listed in `.gitignore` but had been tracked before the rule was added).
- `bin/`: removed the empty committed directory.

## [1.1.4] - 2026-04-30

### Changed

- `build`: regenerate from updated templates to add test/staging integration,
  staging synopsis and argument validation improvements, provenance SHA sync,
  and `dev-latest` tag handling.
- `build`: add leading docstrings to generated helper functions.
- `test`: add regression coverage for scan and hardening fixes.

## [1.1.3] - 2026-04-20

### Added

- `build`: apply the generated Phase 3 build script.

### Fixed

- Scanning: bump Python to 3.14.1, add dive CI thresholds, and add a Grype
  ignore list.

## [1.1.2] - 2026-04-18

### Removed

- Release Please automation.

## [1.1.1] - 2026-04-18

### Changed

- `Dockerfile`: consolidate final-stage `RUN` layers to improve Dive
  efficiency.
- Documentation: add local-dev instructions forbidding direct PR merges.
- Dependencies: bump `python` to `3.14.0-alpine3.22`,
  `docker/build-push-action` to `v7`, `actions/checkout` to `v6`, and
  `hadolint/hadolint-action` to `v3.3.0`.

## [1.1.0] - 2026-04-16

### Fixed

- `Dockerfile`: remove `pip` from the final image to reduce CVE surface.

### Changed

- CI: replace legacy workflows with shared workflow delegation, standard CI,
  build caching, pinned GitHub Actions SHAs, Dependabot scanning, semver tag
  sub-tags, release automation, and shellcheck auto-discovery.
- Image metadata: add OCI labels and embedded build metadata.
- Testing: standardize on Bats, add full test-suite coverage, correct image
  metadata tests, and make `--advise`/`--cache` parsing case-insensitive.
- Documentation: add `CLAUDE.md`, `CONTRIBUTING.md`, and `SECURITY.md`, and
  clean up `README.md`.
- Base image: pin `python:3.13.7-alpine3.22` and add Dependabot Docker
  tracking.

## [1.0.5] - 2026-02-23

### Changed

- GitHub workflows: derive the image name from the repository instead of a
  hardcoded value.
- Build pipeline: add Docker Scout and optional Dive advisements.
- Code, docs, and tests: address review findings and align the local build
  procedure with the CI pipeline.

## [1.0.4] - 2026-02-22

### Fixed

- Semver handling and Docker push workflow bugs.
- Version-tag formatting by removing the leading `v` from semver tags.
- Security documentation and version-pinning side-effect test failures.

### Changed

- Build/test workflow: add the standard build script, more test cases,
  multi-architecture builds, SBOM and provenance support, and supporting QEMU,
  Buildx, `yamlint`, and `actionlint` fixes.

## [1.0.3] - 2026-02-22

### Changed

- Code cleanup focused on security and correctness.
- CI, OCI labels, test suite, and documentation improvements.

## [1.0.2] - 2026-02-20

### Fixed

- Address Trivy-reported CVEs by updating `pip`.
- Fix copy/paste errors in the build command.

### Changed

- Add GitHub workflows for building and pushing to Docker Hub.
- Apply code review follow-up changes.
- Add project-wide expectations for GitHub Copilot.

## [1.0.1] - 2025-09-12

### Changed

- Adopt Docker's Python containerization pattern.
- Improve `shellcheck` and `pylint` hygiene.
- Ignore Eclipse project files.
- Add AGPL copyright text and fix copyright notices.

## [1.0.0] - 2025-07-26

### Added

- Initial 1.0.0 release.

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

[Unreleased]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.6...HEAD
[1.1.6]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/1121citrus/canonicalize-json/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/1121citrus/canonicalize-json/compare/1.0.5...v1.1.0
[1.0.5]: https://github.com/1121citrus/canonicalize-json/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/1121citrus/canonicalize-json/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/1121citrus/canonicalize-json/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/1121citrus/canonicalize-json/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/1121citrus/canonicalize-json/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/1121citrus/canonicalize-json/releases/tag/1.0.0
