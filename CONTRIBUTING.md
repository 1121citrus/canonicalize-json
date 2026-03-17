# Contributing to canonicalize-json

## Issues and bug reports

Open an issue at [github.com/1121citrus/canonicalize-json/issues](https://github.com/1121citrus/canonicalize-json/issues).
Include:

- The exact command you ran (redact any sensitive data).
- The input JSON (or a minimal reproducer).
- Expected vs. actual output.
- Docker version (`docker version`) and host OS.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make your changes.
3. Run the test suite — all tests must pass:

   ```bash
   ./build
   bash test/run-all-tests
   ```

4. Run shellcheck locally on any shell files you changed:

   ```bash
   shellcheck -x src/canonicalize-json build test/run-all-tests test/bin/*
   ```

5. Run hadolint if you changed the Dockerfile:

   ```bash
   docker run --rm -i hadolint/hadolint < Dockerfile
   ```

6. Open a pull request against `main`.  The CI pipeline will lint, build,
   test, and scan automatically.

## Dependency version bumps

### Python dependency (`requirements.txt`)

After changing the `jcs` version:

```bash
pip download --no-deps "jcs==<new-version>"
pip hash jcs-<new-version>*.whl jcs-<new-version>.tar.gz
```

Update both hash lines in `requirements.txt`.  The Dockerfile enforces
`--require-hashes` so a mismatched or missing hash will cause the build to fail.

### Base image (`Dockerfile`)

When bumping `PYTHON_VERSION` or `ALPINE_VERSION`, verify that the specific
`python:<PYTHON_VERSION>-alpine<ALPINE_VERSION>` tag exists on Docker Hub
before merging.

### GitHub Actions

Action versions in `.github/workflows/ci.yml` are managed by Dependabot
(see `.github/dependabot.yml`).  Automated PRs are created weekly.

## Coding conventions

- Shell scripts: POSIX sh compatible where possible; Bash 4+ where needed.
  Prefer `set -Eeuo pipefail` at the top of every Bash script.
- Python: standard library only (plus `jcs`).  No additional runtime
  dependencies.
- All new shell files must pass `shellcheck`.
- All new test functions follow the `test_<noun>_<condition>` naming pattern.

## License

By contributing, you agree that your contributions will be licensed under the
[GNU Affero General Public License v3.0 or later](LICENSE.md).
