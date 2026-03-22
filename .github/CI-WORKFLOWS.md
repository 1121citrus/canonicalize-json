# GitHub CI Workflows

Automated linting, building, testing, security scanning, and multi-branch Docker image publication for the canonicalize-json utility.

## Workflow Overview

| Stage | Trigger | Purpose | Branches |
| --- | --- | --- | --- |
| **Lint** | main, master, staging, tags, PRs to main/master | Validate Dockerfile and shell scripts | All triggers |
| **Build** | main, master, staging, tags, PRs to main/master | Build and cache Docker image | All triggers |
| **Test** | main, master, staging, tags, PRs to main/master | Run integration tests | All triggers |
| **Scan** | main, master, staging, tags, PRs to main/master | Vulnerability scanning with Trivy | All triggers |
| **Push** | main, master, staging, version tags | Multi-platform build and push to Docker Hub | Production branches only |

## CI Workflow (`ci.yml`)

Unified workflow handling all CI/CD stages with support for multiple production branches (main, master, staging) and semantic version tags.

### Trigger Events

- **Push:**
  - Branches: main, master, staging
  - Tags: `v*` (semantic version format)
- **Pull requests:** To main or master branches

### Global Configuration

- **Image name:** `1121citrus/canonicalize-json`
- **Permissions:** Minimal (contents: read); jobs request only what they need
- **Workflow strategy:** Multi-branch support with distinct tagging for each branch

---

## Stage 1: Lint

Validates Dockerfile and shell scripts before building.

### Stage 1 Steps

1. **Checkout Code**

2. **Lint Dockerfile with hadolint**
   - Uses hadolint v3.1.0
   - Checks for best practices and anti-patterns

3. **Lint shell scripts with shellcheck**
   - Targets: `src/canonicalize-json`, `build`, `test/run-all-tests`, all `test/bin/*`
   - Enables dependency resolution (`-x` flag)

---

## Stage 2: Build

Builds Docker image and exports for downstream jobs to avoid rebuilds.

### Stage 2 Steps

1. **Set build metadata**
   - Derives version from git ref (used to tag the local image for test/scan):
     - `refs/tags/v1.2.3` → version `1.2.3`
     - `refs/heads/main`, `refs/heads/master` → version `main` / `master`
       (the push stage re-tags this as `:edge`)
     - `refs/heads/staging` → version `staging`
       (the push stage re-tags this as `:staging-<timestamp>`)
     - Pull requests → version `pr-<PR-number>`
   - Captures short commit hash and UTC build timestamp

2. **Set up Docker Buildx**

3. **Build image**
   - **Tag:** `1121citrus/canonicalize-json:<version>`
   - **Note:** `:latest` tag is **NOT** applied in build stage
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Output:** Loaded locally (`load: true`)

4. **Save image for downstream jobs**
   - Exports to `/tmp/image.tar.gz`
   - Ensures test and scan jobs work with identical image

5. **Upload image artifact**
   - GitHub Actions artifact with 1-day retention

**Artifact Name:** `docker-image`

---

## Stage 3: Test

Runs integration test suite against built image.

### Stage 3 Steps

1. **Download image artifact**

2. **Load image**

3. **Run test suite**
   - Executes `test/run-all-tests`
   - **Environment:** `TAG` set to the version produced by the build stage (e.g., `1.2.3`, `main`, `staging`)
   - Uses bash explicitly (`bash test/run-all-tests`)
   - **Note:** Uses version-specific tag instead of `:latest` since `:latest` may not exist locally during PR testing

---

## Stage 4: Security Scan

Scans built image for known vulnerabilities.

### Stage 4 Steps

1. **Download image artifact**

2. **Load image**

3. **Trivy vulnerability scan**
   - **Version:** 0.35.0 (pinned for supply-chain security)
   - **Scope:** All severity levels (CRITICAL, HIGH, MEDIUM, LOW)
   - **Image tag:** Derived from the build job's `version` output (e.g., `1.2.3`, `main`, `staging`)
   - **Behavior:**
     - `exit-code: 1` — **Fails job** if fixable vulnerabilities found
     - `ignore-unfixed: true` — Suppresses unfixable CVEs (reduces noise)
   - **Output format:** Table
   - **Blocks push** if any fixable HIGH or CRITICAL CVEs detected

---

## Stage 5: Push to Docker Hub

Builds and publishes multi-platform image to Docker Hub.

### Trigger Condition

- **Events:** `push` only (no PRs)
- **Refs:**
  - `refs/heads/main`
  - `refs/heads/master`
  - `refs/heads/staging`
  - `refs/tags/v*` (semantic version tags)

### Permissions

- `contents: read` only (Docker Hub auth uses secrets, not OIDC)

### Stage 5 Steps

1. **Set build metadata**
   - Version logic:
     - Version tag (`refs/tags/v1.2.3`) → `1.2.3`
     - Staging branch → `staging-YYYY.MM.DD.HHMMSS` (timestamp format)
     - Main/master branch → `edge`
   - Captures commit hash and build timestamp

2. **Set up QEMU** — Cross-platform (arm64 on amd64)

3. **Set up Docker Buildx**

4. **Log in to Docker Hub**
   - Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

5. **Determine tags**
   - **Version tag:** `<image>:<version>` + `<image>:latest` (`:latest` only for releases)
   - **Staging branch:** `<image>:<timestamp>` + `<image>:staging`
   - **Main/master branch:** `<image>:edge` only
   - **Design:** `:latest` reserved for released versions; branch builds get branch-specific tags

6. **Build and push (multi-platform)**
   - **Platforms:** `linux/amd64`, `linux/arm64`
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Attestations:**
     - `sbom: true` — SPDX Software Bill of Materials
     - `provenance: mode=max` — SLSA Build Provenance Level 3
   - **Caching:** No layer caching (push job rebuilds from scratch)

---

## Configuration Reference

### Required Secrets

- `DOCKERHUB_USERNAME` — Docker Hub username
- `DOCKERHUB_TOKEN` — Docker Hub authentication token

### Build Arguments (Dockerfile)

- `VERSION` — Version string (semantic, edge, staging, or pr-number)
- `GIT_COMMIT` — Short commit hash
- `BUILD_DATE` — ISO 8601 UTC timestamp

### Multi-Branch Strategy

| Branch | Image Tag | `:latest` | Use Case |
| --- | --- | --- | --- |
| main | `1121citrus/canonicalize-json:edge` | No | Development builds from main |
| master | `1121citrus/canonicalize-json:edge` | No | Legacy main branch (if used) |
| staging | `1121citrus/canonicalize-json:staging-<timestamp>` | No | Pre-release testing |
| v1.2.3 (tag) | `1121citrus/canonicalize-json:1.2.3` | Yes | Released production version |

---

## Execution Flow

```text
On push to any branch or PR to main/master
    ↓
[Lint Job]
  - Hadolint (Dockerfile)
  - Shellcheck (shell scripts)
  - Pass → Proceed
  - Fail → Blocks downstream

[Build Job]
  - Build image locally
  - Export to artifact
  - Metadata: version, commit, date

[Test Job] (after Build)
  - Load image from artifact
  - Run integration tests
  - Pass → Proceed to Push gate
  - Fail → Blocks Push

[Scan Job] (after Build, parallel with Test)
  - Load image from artifact
  - Run Trivy scan
  - No fixed HIGH/CRITICAL → Proceed
  - Fixed HIGH/CRITICAL found → Blocks Push

[Push Job] (after Test & Scan, conditional)
  - Only on: main, master, staging branches or v* tags
  - Multi-platform build & push
  - Tagging:
    - Version tag  → image:X.Y.Z + image:latest
    - Staging      → image:staging + image:staging-YYYY.MM.DD.HHMMSS
    - Main/master  → image:edge
```

---

## Tagging Strategy

The push stage implements a deliberate tagging scheme so that `:latest` always points to a released version.

### Released Versions (Version Tags)

```bash
git tag v1.2.3
# Pushes as:
#   1121citrus/canonicalize-json:1.2.3
#   1121citrus/canonicalize-json:latest
```

### Staging Branch

```bash
git push origin staging
# Pushes as:
#   1121citrus/canonicalize-json:staging-2026.03.18.134500
#   1121citrus/canonicalize-json:staging
```

### Production Branches (main/master)

```bash
git push origin main
# Pushes as:
#   1121citrus/canonicalize-json:edge
```

**Rationale:**

- `:latest` only points to released (tagged) versions
- Branch builds get branch-specific tags to avoid overwriting stable releases
- Staging gets timestamped tags for historical tracking
- Edge builds use `edge` tag for CI integrations that want main-branch images

---

## Design Patterns

### Image Artifact Sharing

All downstream jobs (test, scan, push) share the built image via GitHub Actions artifacts rather than rebuilding. This ensures:

- **Consistency:** All jobs test/scan the exact same image
- **Performance:** Single build, reused by multiple jobs
- **Cost:** Reduced GitHub Actions compute time

### Minimal Permissions

The workflow demonstrates least-privilege permissions:

- Global: `contents: read` only
- Individual jobs request additional permissions only if needed
- Example: Only push job needs Docker Hub credentials (via secrets, not extra permissions)

### Multi-Platform Support

- QEMU-based cross-compilation (arm64 on amd64 runner)
- Build arguments consistent across platforms
- SBOM and provenance generated for both architectures

### Vulnerability Gating

- Scan job blocks push if fixable HIGH/CRITICAL CVEs found
- Unfixed CVEs ignored (non-blocking) to reduce noise
- Allows visibility into all issues while blocking only those with available fixes

---

## Monitoring and Troubleshooting

### Lint Failures

- **Hadolint:** Review Dockerfile against [hadolint rules](https://github.com/hadolint/hadolint/wiki/Rules)
- **Shellcheck:** Fix shell syntax issues (quotes, variable expansion, etc.)

### Build Failures

- Check `Dockerfile` syntax and `FROM` image availability
- Verify all `ARG` directives are defined before use
- Check for network timeouts during package installation

### Test Failures

- Examine `test/run-all-tests` output for specific assertions
- Verify test fixtures in `test/` are present
- Check environment variables and TAG setting

### Scan Failures

- Review Trivy output for specific CVEs
- For unfixed CVEs: Wait for upstream patches or document in `SECURITY.md`
- For fixed CVEs: Update base image or dependencies

### Push Failures

- Verify Docker Hub credentials (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`)
- Confirm token has read/write permissions
- Check repository visibility and access

### Multi-Platform Build Issues

- ARM64 emulation (QEMU) can be slow; check CI logs for progress
- For faster multi-arch builds, use self-hosted runners with native arm64

---

## Related Files

- `Dockerfile` — Container build definition
- `src/canonicalize-json` — Entrypoint shell script
- `build` — Local build and test orchestration script
- `test/run-all-tests` — Integration test suite runner
