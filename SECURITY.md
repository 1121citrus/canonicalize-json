# Security Policy

## Security Design

The image is built with defence-in-depth from the ground up:

| Control | Implementation |
| --- | --- |
| Non-root execution | Dedicated `canonicalize-json` user, UID 10001, shell `/sbin/nologin` |
| Minimal base image | `python:3.13.x-alpine3.22` — Alpine 3.22 includes jq 1.8.x which resolves all previously open jq CVEs |
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

`jcs 0.2.1` is clean per both Trivy and pip-audit.  `pip` is uninstalled
from the final image (only needed in the `builder` stage) so it does not
appear in Trivy's package inventory.

### Alpine OS packages — 0 CVEs

All Alpine packages are patched via `apk upgrade --no-cache` at build time.
See [Dockerfile](Dockerfile) and the associated changelog entry.

### jq — 3 CVEs resolved (Alpine 3.22 / jq 1.8.1)

The upgrade to Alpine 3.22 (`jq 1.8.1-r0`) resolves all three CVEs listed below.
They are retained here for historical reference and to document the analysis that
justified accepting them while the upgrade path was pending.

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

### Remediation status for jq CVEs

All three CVEs are resolved by the upgrade to Alpine 3.22 (`jq 1.8.1-r0`),
completed when the base image was pinned to `python:3.13.7-alpine3.22`.
No further action is required.

---

## Dependency Policy

| Component | Pinning strategy |
| --- | --- |
| Python base image | Pinned to `python:3.13.x-alpine3.22`; Dependabot opens PRs for bumps |
| Alpine OS packages | Upgraded to latest patch via `apk upgrade --no-cache` at every build |
| pip | Installed via `--require-hashes` with exact version in `requirements.txt` |
| Python dependencies | Exact version + SHA-256 hash in `requirements.txt`; `--require-hashes` enforced |
| GitHub Actions | SHA-pinned to full commit hash; Dependabot updates weekly |
| jq | Latest available in pinned Alpine minor; no separate pin needed beyond the base image |
