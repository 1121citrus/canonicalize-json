# Security Policy

## Security Design

The image is built with defence-in-depth from the ground up:

| Control | Implementation |
| --- | --- |
| Non-root execution | Dedicated `canonicalize-json` user, UID 10001, shell `/sbin/nologin` |
| Minimal base image | `python:3.15.x-alpine3.24` — Alpine 3.24 includes jq 1.8.x which resolves all previously open jq CVEs; unused `sqlite-libs` is removed |
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

Scanned **2026-11-15** during the local `./build` pipeline.

- Trivy: no findings.
- Grype: one unignored LOW finding, CVE-2026-103995 in Python 3.15.2.
- Docker Scout: no vulnerable packages.
- No unignored CRITICAL or HIGH findings. Two MEDIUM findings remain
  suppressed because no safe fix is available in the pinned stable base:
  Python CVE-2026-116566 and BusyBox CVE-2025-60876.

### Python dependencies — 0 CVEs

`jcs 0.2.1` is clean per both Trivy and pip-audit.  `pip` is uninstalled
from the final image (only needed in the `builder` stage) so it does not
appear in Trivy's package inventory.

### Alpine OS packages

`apk upgrade --no-cache` applies available Alpine patches at build time.
The image removes unused `sqlite-libs`, requires patched `zlib`, and pins
the fixed `musl` packages from Alpine edge. BusyBox CVE-2025-60876 remains
suppressed because Alpine 3.24 has no fix; the edge BusyBox package adds
three HIGH Grype findings and is not used.

### jq — 3 CVEs resolved (Alpine 3.24 / jq 1.8.2)

The upgrade to Alpine 3.24 (`jq 1.8.2-r0`) resolves all three CVEs listed below.
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

### Python runtime — 1 CVE (no fix available)

| CVE | Severity | Fixed in |
| --- | --- | --- |
| CVE-2026-116566 | MEDIUM | 3.16.0 |

Present in Python 3.15.2 with no stable 3.15.x fix as of 2026-11-15.
Suppressed in `.grype.yaml`.  Remove the ignore entry when CPython ships
a patched 3.15.x release, or when this image moves to Python 3.16.
CVE-2026-103995 (LOW, fixed in 3.16.0) is also reported; it does not gate
the build and is not suppressed.

The base-image move to `python:3.15.2-alpine3.24` (from `3.14.8-alpine3.24`)
resolved CVE-2026-115557 (CRITICAL), CVE-2026-119170 (HIGH), and
CVE-2026-87910, CVE-2026-114583, CVE-2025-15367, and CVE-2026-12345 (all
MEDIUM).  The 3.14 line had no released fix for CVE-2026-119170 (fixed in
the unreleased 3.14.11), so the image moved to the stable 3.15 line.
`jcs` is pure Python and its output is unchanged.  The ignore entries for
CVE-2025-15367 and CVE-2026-12345 have been removed.

The base-image bump to `python:3.14.8-alpine3.24` (from `3.14.5-alpine3.22`)
resolved CVE-2026-6100 (CRITICAL), CVE-2026-7210 (CRITICAL),
CVE-2026-3298 (HIGH), CVE-2026-4786 (HIGH), and a further batch of HIGH
and MEDIUM CVEs (CVE-2026-11940, CVE-2026-11972, CVE-2026-15308,
CVE-2026-19445, CVE-2026-19553, CVE-2026-17084, CVE-2026-7774,
CVE-2026-9669, CVE-2026-15806, CVE-2026-3276, CVE-2026-19672,
CVE-2026-8328, CVE-2026-4360, CVE-2026-15310, CVE-2026-6879,
CVE-2026-12003, CVE-2026-0864, CVE-2026-18503) that were previously
flagged by Grype.  Their `.grype.yaml` ignore entries have been removed
accordingly.

---

### Alpine OS package remediation

`zlib` is required at `>=1.4-r0`, resolving CVE-2026-4738 (CRITICAL).
`sqlite-libs` 3.53.4-r0 carries CVE-2026-119373, CVE-2026-119374,
CVE-2026-119379, CVE-2026-119586 (HIGH), CVE-2026-119371,
CVE-2026-119372, CVE-2026-119375, CVE-2026-119376, CVE-2026-119378,
CVE-2026-119591 (MEDIUM), and CVE-2026-119377 (LOW), with no fix in
Alpine 3.24.  Nothing in this image uses SQLite, so the final stage
removes `sqlite-libs` and Python's `sqlite3` module instead of
suppressing them.

Alpine 3.24 has not yet published the musl CVE-2026-107891 (HIGH) fix.
The final image pins `musl` and `musl-utils` 1.2.6-r6 from Alpine edge.
Remove these pins after Alpine publishes the same package versions in the
stable 3.24 repository.

BusyBox CVE-2025-60876 (MEDIUM) remains in `busybox`, `busybox-binsh`, and
`ssl_client` 1.37.0-r31. It is suppressed in `.grype.yaml` because Alpine
3.24 has no fix. Alpine edge's BusyBox 1.38.0-r8 introduces three High
Grype findings, so the image retains the stable BusyBox packages until a
safe patched release is available.

The Alpine minor bump to 3.24 (alongside the Python base-image bump above)
resolved CVE-2025-70873 (`sqlite-libs`, HIGH) and two newly surfaced HIGH
`sqlite-libs` CVEs (CVE-2026-11822, CVE-2026-11824) caught in this scan
cycle; their `.grype.yaml` ignore entry has been removed.

---

### Remediation status for jq CVEs

All three CVEs are resolved by the upgrade to Alpine 3.22 (`jq 1.8.1-r0`),
completed when the base image was pinned to `python:3.14.1-alpine3.22`.
No further action is required.

---

## Dependency Policy

| Component | Pinning strategy |
| --- | --- |
| Python base image | Pinned to `python:3.15.2-alpine3.24`; Dependabot opens PRs for patch bumps |
| Alpine OS packages | Upgraded to latest patch via `apk upgrade --no-cache` at every build |
| pip | Installed via `--require-hashes` with exact version in `requirements.txt` |
| Python dependencies | Exact version + SHA-256 hash in `requirements.txt`; `--require-hashes` enforced |
| GitHub Actions | SHA-pinned to full commit hash; Dependabot updates weekly |
| jq | Latest available in pinned Alpine minor; no separate pin needed beyond the base image |
