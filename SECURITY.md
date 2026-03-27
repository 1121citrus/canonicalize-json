# Security policy

## Reporting a vulnerability

Report security vulnerabilities through the
[GitHub Security tab](https://github.com/1121citrus/canonicalize-json/security).
Do not open a public GitHub issue for security vulnerabilities.

---

## Supported versions

| Tag | Status |
| --- | --- |
| `latest` | Supported (current stable release) |
| Older tags | Not supported — upgrade to `latest` |

---

## Defense-in-depth measures

| Measure | How |
| --- | --- |
| Non-root user | Container runs as UID 10001 (`canonicalize-json`); no login shell, no home dir |
| Minimal package surface | Only `jq` added beyond the Python Alpine base; base image upgraded at build time |
| Python Alpine base + `apk upgrade` | Resolves OS-level CVEs in the base layer at build time |
| Pinned action versions | CI actions pinned to version tags (not `@master`) to reduce supply-chain risk |
| SBOM + provenance | Multi-platform push includes `--sbom=true --provenance=mode=max` |
