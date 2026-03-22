# Security Policy

## Security Design

The image is built with defence-in-depth from the ground up:

| Control | Implementation |
| --- | --- |
| Non-root execution | Dedicated `canonicalize-json` user, UID 10001, shell `/sbin/nologin` |
| Minimal base image | `python:3.13.x-alpine3.21` — no package manager, no shell utilities beyond what Alpine includes |
| Supply-chain pinning | `pip install --require-hashes` with explicit SHA-256 digests for every Python dependency |
| OS patch hygiene | `apk upgrade --no-cache` runs at image-build time, pulling in all available Alpine security patches |
| No network at runtime | Image makes no outbound connections; suitable for `--network=none` |
| Read-only filesystem | No files are written at runtime; compatible with `--read-only --tmpfs /tmp` |
| Least-privilege Python | `PYTHONDONTWRITEBYTECODE=1`, `PYTHONUNBUFFERED=1` |
| SLSA Build Provenance | SLSA Level 3 attestations on every published image |
| SBOM attestation | SPDX SBOM attached to every published image |
| Vulnerability scanning | Trivy (Aqua) scans every CI build; fixable HIGH/CRITICAL CVEs block the pipeline |

---

## Current Vulnerability Status

Scanned **2026-03-18** against `1121citrus/canonicalize-json:dev`.

### Python packages — 0 CVEs

`jcs 0.2.1` and `pip 26.0.1` are clean per both Trivy and pip-audit.

### Alpine OS packages — 0 CVEs

All Alpine packages are patched via `apk upgrade --no-cache` at build time.
See [Dockerfile](Dockerfile) and the associated changelog entry.

### jq — 3 open CVEs (accepted, mitigated)

jq `1.7.1-r0` is the only version published for Alpine 3.21 as of this writing.
All three CVEs below have **no fixed version available in Alpine 3.21**; they are
fixed upstream in jq 1.8.x and in Alpine edge (`jq 1.8.1-r0`).

The image's exposure is **structurally limited** because jq is invoked in exactly
one place (`src/canonicalize-json`, line `jq --indent "${INDENT:-2}" .`) and only
when the user explicitly opts in via `PRETTIFY=true`.  There are no user-supplied
jq filters, no `--slurp` flag, and no arithmetic operations — the sole function is
formatting already-parsed JSON for human readability.

#### CVE-2024-53427 — Stack buffer overflow in NaN handling

| Field | Detail |
| --- | --- |
| Severity | HIGH (CVSS 8.1) |
| Alpine 3.21 fix | Not available |
| Upstream fix | jq 1.8.0 |
| CWE | CWE-843 (Type Confusion), CWE-121 (Stack Buffer Overflow) |

**Summary:** The `decNumberCopy` function in `decNumber.c` mishandles NaN payloads
(e.g., `NaN123`), causing a stack-based out-of-bounds write.

**Trigger conditions:** Requires the `--slurp` flag *and* an arithmetic filter
(e.g., `.-`) operating on input containing a NaN digit string.

**Impact on this image:** **Not exploitable.**  This image invokes jq exclusively
as `jq --indent N .`; neither `--slurp` nor any arithmetic filter is used.  The
NaN-parsing code path is never reached.

---

#### CVE-2025-48060 — Heap buffer overflow in string formatting

| Field | Detail |
| --- | --- |
| Severity | HIGH (CVSS 7.7 v4.0 / 7.5 v3.1) |
| Alpine 3.21 fix | Not available |
| Upstream fix | jq 1.7.2 |
| CWE | CWE-787 (Out-of-bounds Write) |

**Summary:** `jv_string_vfmt` in `jv.c` under-allocates heap memory when
calculating the output buffer size for formatted strings, enabling a heap
out-of-bounds write with specially crafted input.

**Trigger conditions:** Requires specially crafted JSON input that causes
pathological string-formatting behavior inside jq.

**Impact on this image:** **Reduced.**  jq does invoke string formatting during
pretty-printing, so the code path is reachable.  However, JSON input arrives
*after* Python's `json.load()` has already parsed and re-serialised it via
`jcs.canonicalize()`.  The output of those two stages is a well-formed,
canonically structured UTF-8 string — not attacker-controlled raw bytes.  A
successful exploit would require a JSON value that survives RFC 8785
normalisation and still triggers the allocation underestimate; that is a
significantly narrowed attack surface.  Trivy reports this as unfixed in
Alpine 3.21; it is accepted pending the Alpine 3.22 / jq 1.8.x
upgrade path below.

---

#### CVE-2024-23337 — Integer overflow in array/object operations

| Field | Detail |
| --- | --- |
| Severity | MEDIUM (CVSS 6.5) |
| Alpine 3.21 fix | Not available |
| Upstream fix | jq commit de21386 |
| CWE | CWE-190 (Integer Overflow) |

**Summary:** Signed integer overflow in `jvp_array_write` / `jvp_object_rehash`
when an array is indexed at `2147483647` (INT32_MAX), causing a crash (SEGV).

**Trigger conditions:** Requires deliberate construction of an array or object
using the maximum signed 32-bit integer as an index.  This is a denial-of-service
condition (crash), not a code-execution path.

**Impact on this image:** **Not exploitable.**  jq is invoked only for formatting
output produced by `jcs.canonicalize()`.  That output contains no manufactured
index operations; the integer boundary is never approached during indentation.

---

### Remediation path for jq CVEs

All three CVEs are resolved in jq 1.8.x (available in Alpine edge as
`jq 1.8.1-r0`).  The planned upgrade path is:

1. **Pin to Alpine 3.22** once `python:3.13.x-alpine3.22` is published to
   Docker Hub (Alpine 3.22 ships jq 1.8.x in its main repository).
2. **Or add an Alpine edge package overlay** — mount only the `community` repo
   from Alpine edge for the jq package while keeping the base image on 3.21.
   This is a viable interim option but is more complex to maintain.

Until one of these options is available, the three CVEs are accepted with the
mitigations documented above.  The CI pipeline is configured with
`--ignore-unfixed` so that unfixable CVEs do not block builds, while fixable
HIGH/CRITICAL vulnerabilities remain blocking.

---

## Dependency Policy

| Component | Pinning strategy |
| --- | --- |
| Python base image | Minor version pinned (`python:3.13.x-alpine3.21`); patch bumped by Dependabot |
| Alpine OS packages | Upgraded to latest patch via `apk upgrade --no-cache` at every build |
| pip | Exact version pin in Dockerfile (`pip==x.y.z`) |
| Python dependencies | Exact version + SHA-256 hash in `requirements.txt`; `--require-hashes` enforced |
| GitHub Actions | SHA-pinned to full commit hash; Dependabot updates weekly |
| jq | Latest available in pinned Alpine minor; no separate pin needed beyond the base image |
