# Contributing

## Prerequisites

- Docker with buildx support
- Bash 4.0+ (macOS ships 3.2 — install via [Homebrew](https://brew.sh/): `brew install bash`)

## Development workflow

### Building

The `build` script runs all stages: lint → build → test → scan → push.

```bash
./build              # Local build and test
./build --push       # Push to Docker Hub after successful scan
./build --help       # See all options
```

Individual stages can be skipped:

```bash
./build --no-lint    # Skip hadolint, shellcheck, and markdownlint
./build --no-scan    # Skip Trivy (and advisory scans by default)
./build --no-test    # Skip the test suite
```

### Testing

The full suite runs through the build script:

```bash
./build --no-lint --no-scan   # Build and test only
```

Or directly against an already-built image:

```bash
bash test/run-all-tests
```

See `test/` for the individual test suites.

### Code style

All shell scripts must pass:

```bash
shellcheck src/ test/
hadolint Dockerfile
```

All Markdown must pass:

```bash
markdownlint **/*.md
```

These checks run automatically in stage 1 of `./build`.

### Advisory scans

Non-gating Grype, Docker Scout, and Dive scans are available:

```bash
./build --advise              # Default: grype + scout
./build --advise all          # All three: grype, scout, dive
```

### Submitting changes

1. Branch from `main`.
2. Make your changes.
3. Run `./build` to lint, test, and scan.
4. Submit a pull request targeting `main`.

## Release process

Releases are tag-driven via release-please. Pushing a version tag
triggers GitHub Actions to build a multi-platform image and push to
Docker Hub as `<version>` and `latest`.

See `.github/CI-WORKFLOWS.md` for the full CI pipeline description.
