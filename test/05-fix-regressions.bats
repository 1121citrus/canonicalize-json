#!/usr/bin/env bats
# test/05-fix-regressions.bats — regression checks for bug-fix commits.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    REPO_ROOT="${BATS_TEST_DIRNAME}/.."
    BUILD_SCRIPT="${REPO_ROOT}/build"
    DOCKERFILE="${REPO_ROOT}/Dockerfile"
    GRYPE_CONFIG="${REPO_ROOT}/.grype.yaml"
    DIVE_CONFIG="${REPO_ROOT}/.dive-ci"
}

@test "build _timed tolerates watcher wait under set -e" {
    run grep -F 'wait "${_watcher}" 2>/dev/null || true' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "build validates required values for version platform and registry" {
    run grep -F '_require_value "$1" "${2:-}"' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "build loads grype config when .grype.yaml exists" {
    run grep -F '_grype_cfg=(--config /.grype.yaml)' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test ".grype.yaml gates failures at high severity" {
    run grep -F 'fail-on-severity: "high"' "${GRYPE_CONFIG}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile removes pip from final image" {
    run grep -F 'python -m pip uninstall -y pip' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
}

@test "Dockerfile pins python 3.14.5 in both stages" {
    run grep -c '^FROM python:3\.14\.5-alpine3\.22' "${DOCKERFILE}"
    [ "$status" -eq 0 ]
    [ "$output" -eq 2 ]
}

@test ".dive-ci defines explicit lowestEfficiency threshold" {
    run grep -F 'lowestEfficiency: 0.82' "${DIVE_CONFIG}"
    [ "$status" -eq 0 ]
}

@test ".dive-ci disables highestWastedBytes threshold" {
    run grep -F 'highestWastedBytes: disabled' "${DIVE_CONFIG}"
    [ "$status" -eq 0 ]
}
