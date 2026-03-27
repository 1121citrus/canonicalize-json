# GitHub CI workflows

Automated linting, building, testing, security scanning, and Docker image publication
for the canonicalize-json utility.

## Workflow overview

| Stage | Trigger | Purpose |
| ----- | ------- | ------- |
| **Lint** | All pushes, PRs to main/master, tags | Validate Dockerfile and shell scripts |
| **Build** | After lint | Build image and share as artifact |
| **Test** | After build (parallel with scan) | Run integration test suite |
| **Scan** | After build (parallel with test) | Trivy image scan — blocks push on fixable CVEs |
| **Push** | Version tags and staging branch only | Multi-platform build and push to Docker Hub |
| **Dependabot** | Weekly (Monday 06:00 UTC) | Keep GitHub Actions and pip dependencies current |
| **Release Please** | Push to main/master | Open release PR; create tag and GitHub Release |

## CI workflow (`ci.yml`)

Lint, Build, Scan, and Push delegate to shared reusable workflows in
[1121citrus/shared-github-workflows](https://github.com/1121citrus/shared-github-workflows).
The Test job is defined inline because it is specific to this repo.

### Global configuration

- **Image name:** `1121citrus/canonicalize-json`

### Trigger events

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
# Publishes: 1121citrus/canonicalize-json:1.2.3 + :1.2 + :1 + :latest
```

---

## Stage 1: Lint

Shared workflow: `lint.yml` — runs Hadolint, ShellCheck, and markdownlint-cli.

---

## Stage 2: Build

Shared workflow: `build.yml` — builds image once and exports it as the
`docker-image` artifact so test and scan jobs use the identical image.
Re-tagged as `:latest` for test script compatibility. Artifact retention: 1 day.

---

## Stage 3: Test

Inline job. Downloads the artifact, loads the image, and runs the bats suite
in a `bats/bats:1.13.0` container with the Docker socket mounted:

- `test/01-build.bats` — image build assertions
- `test/02-canonicalize.bats` — JSON canonicalization output
- `test/03-prettify.bats` — pretty-print mode
- `test/04-image-metadata.bats` — OCI label verification

---

## Stage 4: Security scan

Shared workflow: `scan.yml` — Trivy CRITICAL/HIGH scan of the built image
before it is pushed. Fails and blocks push on any fixable CVE.

---

## Stage 5: Push to Docker Hub

Shared workflow: `push.yml` — runs only on version tags and the staging
branch; never on plain main pushes.

### Tagging

| Trigger | Docker Hub tags |
| ------- | --------------- |
| Tag `v1.2.3` | `1121citrus/canonicalize-json:1.2.3` + `:1.2` + `:1` + `:latest` |
| Push to `staging` | `1121citrus/canonicalize-json:staging-<sha>` + `:staging` |

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)

---

## Execution flow

```text
On push/PR
    ↓
[Lint] — shared: hadolint + shellcheck + markdownlint
    ↓
[Build] — shared: single-arch image → artifact
    ↓ (parallel)
[Test]                        [Scan]
 - load artifact               - shared: Trivy CRITICAL/HIGH
 - bats in bats:1.13.0         - ✅/❌ blocks push
 - ✅/❌

[Push] (tags and staging only, after Test + Scan pass)
 - shared: QEMU + Buildx multi-arch
 - push amd64 + arm64
 - SBOM + provenance
```

---

## Configuration reference

### Required secrets

- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub access token

### Key files

- `Dockerfile` — container build definition
- `src/canonicalize-json` — shell entrypoint (wraps `canonicalize_json.py`)
- `src/canonicalize_json.py` — Python JCS implementation
- `requirements.txt` — Python dependencies (pip)
- `build` — local build script
- `test/run-all-tests` — integration test runner
- `test/bin/canonicalize` — canonicalization test
- `test/bin/prettify` — pretty-print test

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions and
Python (pip) dependencies current.

- **Schedule:** Every Monday at 06:00 UTC
- **Scope:** GitHub Actions + Python pip
- **Labels:** `dependencies`, `github-actions` / `dependencies`, `python`

---

## Automated releases (release-please)

`release-please.yml` delegates to the shared `release-please.yml` workflow.
It watches for [conventional commits](https://www.conventionalcommits.org/)
merged to `main`/`master` and automates the release lifecycle:

1. Opens a "release PR" that bumps `version.txt`, prepends to `CHANGELOG.md`,
   and proposes the next semver tag
2. When the release PR is merged, creates a GitHub Release and pushes the tag
3. The CI `push` job fires on the new tag and publishes the Docker image

### Conventional commit types that trigger version bumps

| Commit prefix | Bump |
| ------------- | ---- |
| `fix:` | patch (1.0.x) |
| `feat:` | minor (1.x.0) |
| `feat!:` or `BREAKING CHANGE:` | major (x.0.0) |

All other prefixes (`ci:`, `docs:`, `chore:`, `refactor:`, `test:`, etc.)
appear in the changelog but do not trigger a version bump on their own.

### Configuration

- `release-please-config.json` — release type (`simple`) and package root
- `.release-please-manifest.json` — current version
- `version.txt` — plain-text version file
- `CHANGELOG.md` — generated/updated by release-please
