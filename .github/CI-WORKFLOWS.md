# GitHub CI Workflows

Automated linting, building, testing, security scanning, and Docker image publication
for the canonicalize-json utility.

## Workflow Overview

| Stage          | Trigger                              | Purpose                                          |
| -------------- | ------------------------------------ | ------------------------------------------------ |
| **Lint**       | All pushes, PRs to main/master, tags | Validate Dockerfile and shell scripts            |
| **Build**      | After lint                           | Build image and share as artifact                |
| **Test**       | After build (parallel with scan)     | Run integration test suite                       |
| **Scan**       | After build (parallel with test)     | Trivy image scan — blocks push on fixable CVEs   |
| **Push**       | Version tags and staging branch only | Multi-platform build and push to Docker Hub      |
| **Dependabot** | Weekly (Monday 06:00 UTC)            | Keep GitHub Actions and pip dependencies current |

## CI Workflow (`ci.yml`)

Single unified workflow for all CI/CD stages.

### Trigger Events

- **Push:** `main`, `master`, `staging` branches and `v*` version tags
- **Pull requests:** To `main` or `master` branches

### Concurrency

- **Group:** `<workflow-name>-<ref>` — one concurrent run per workflow + branch/tag
- **Branches and PRs:** Cancel any in-progress run when a newer one starts
- **Version tags:** Never cancelled — release builds always complete

### Versioning

Tag-driven. Push a git tag to publish a release:

```bash
git tag v1.2.3
git push origin v1.2.3
# Publishes: 1121citrus/canonicalize-json:1.2.3 + :latest
```

No automation bumps the version — the tag is always a deliberate decision.

---

## Stage 1: Lint

- **Hadolint** — Dockerfile best-practice checks
- **ShellCheck** — static analysis with `-x` (source resolution):
  - `src/canonicalize-json`, `build`, `test/run-all-tests`, `test/bin/*`
- **Markdownlint** — `**/*.md` via `markdownlint-cli:v0.48.0`

---

## Stage 2: Build

Builds image once and exports it as a GitHub Actions artifact (`docker-image`) so test
and scan jobs use the identical image. Re-tagged as `:latest` for compatibility with
test scripts that default to `IMAGE:latest`.

Artifact retention: 1 day.

**Docker layer cache:** `cache-from: type=gha` / `cache-to: type=gha,mode=max` — build
layers are saved to and restored from GitHub Actions cache, speeding up incremental
builds. The push job restores from the same cache.

---

## Stage 3: Test

Runs in parallel with the scan job. Downloads the artifact, loads the image, and
executes `test/run-all-tests`:

- `test/bin/canonicalize` — validates JSON canonicalization output
- `test/bin/prettify` — validates pretty-print mode

Tests invoke the application via `docker run` against `IMAGE:latest`.

---

## Stage 4: Security scan

Scans the built image **before** it is pushed to Docker Hub.

- **Tool:** Trivy `aquasecurity/trivy-action@0.35.0` (pinned)
- **Severity:** CRITICAL, HIGH
- **Blocking:** `exit-code: 1` — fails and blocks push if fixable CVEs found
- **Noise reduction:** `ignore-unfixed: true` — suppresses CVEs with no available patch
- **DB caching:** `~/.cache/trivy` is cached between runs with `actions/cache`; the
  vulnerability DB is only re-downloaded when the cache is cold or the DB has been updated
- **Download noise:** `TRIVY_NO_PROGRESS=true` suppresses progress bars; `TRIVY_QUIET=true`
  suppresses `INFO [vulndb]` log lines during DB download

---

## Stage 5: Push to Docker Hub

Runs only when test and scan both pass, and only on version tags or the staging branch.

### Tagging

| Trigger           | Docker Hub tags                                                     |
| ----------------- | ------------------------------------------------------------------- |
| Tag `v1.2.3`      | `1121citrus/canonicalize-json:1.2.3` + `:latest`                    |
| Push to `staging` | `1121citrus/canonicalize-json:staging-<timestamp>` + `:staging`     |

`:latest` is set **only** on version-tagged releases. Staging gets a datetime timestamp
for traceability.

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)
- **Layer cache:** `cache-from: type=gha` / `cache-to: type=gha,mode=max`

---

## Execution Flow

```text
On push/PR
    ↓
[Lint] — hadolint + shellcheck + markdownlint
    ↓
[Build] — single-arch image → artifact
    ↓ (parallel)
[Test]                        [Scan]
 - load artifact               - load artifact
 - run test/run-all-tests      - Trivy CRITICAL/HIGH
 - ✅/❌                        - ✅/❌ blocks push

[Push] (tags and staging only, after Test + Scan pass)
 - QEMU + Buildx multi-arch
 - push amd64 + arm64
 - SBOM + provenance
```

---

## Configuration Reference

### Required Secrets

- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub access token

### Key Files

- `Dockerfile` — Container build definition
- `src/canonicalize-json` — Shell entrypoint (wraps `canonicalize_json.py`)
- `src/canonicalize_json.py` — Python JCS implementation
- `requirements.txt` — Python dependencies (pip)
- `build` — Local build script
- `test/run-all-tests` — Integration test runner
- `test/build-options` — Build script CLI option coverage test
- `test/bin/canonicalize` — Canonicalization test
- `test/bin/prettify` — Pretty-print test

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions and Python (pip)
dependencies current.

- **Schedule:** Every Monday at 06:00 UTC
- **Scope:**
  - GitHub Actions (`package-ecosystem: github-actions`) — updates action pins in
    `.github/workflows/*.yml`
  - Python pip (`package-ecosystem: pip`) — updates `requirements.txt` dependencies
- **Labels:** `dependencies`, `github-actions` / `dependencies`, `python`
- **Security benefit:** Dependabot also proposes SHA-pinned digests (recommended for SLSA /
  OpenSSF Scorecard hardening)

---

## Local Workflow Parity

- `./build` supports `--advice` (alias for `--advise`) and `--cache` for one-run
  scanner cache controls.
- `./build` — local equivalent of the CI build + push pipeline
