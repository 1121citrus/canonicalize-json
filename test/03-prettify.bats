#!/usr/bin/env bats
# test/03-prettify.bats — test canonicalize-json prettify mode.
#
# Copyright (C) 2025 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    IMAGE="${IMAGE:-1121citrus/canonicalize-json:latest}"
    CANONICAL='{"1":{"dec":"49","hex":"31","oct":"61"},"A":{"dec":"65","hex":"41","oct":"101"},"z":{"dec":"122","hex":"7A","oct":"172"}}'
    INPUT='{"z":{"dec":"122","hex":"7A","oct":"172"},"1":{"hex":"31","oct":"61","dec":"49"},"A":{"hex":"41", "dec":"65","oct":"101"}}'
    export IMAGE CANONICAL INPUT
}

@test "PRETTIFY=true produces indented output (default indent 2)" {
    local expected actual
    expected=$(jq --indent 2 . <<< "${CANONICAL}")
    actual=$(printf '%s' "${INPUT}" | docker run -i --rm \
        -e DEBUG=false -e PRETTIFY=true -e INDENT=2 "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}

@test "PRETTIFY=true with INDENT=4 produces 4-space-indented output" {
    local expected actual
    expected=$(jq --indent 4 . <<< "${CANONICAL}")
    actual=$(printf '%s' "${INPUT}" | docker run -i --rm \
        -e DEBUG=false -e PRETTIFY=true -e INDENT=4 "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}

@test "PRETTY_PRINT=true is an alias for PRETTIFY (default indent 2)" {
    local expected actual
    expected=$(jq --indent 2 . <<< "${CANONICAL}")
    actual=$(printf '%s' "${INPUT}" | docker run -i --rm \
        -e DEBUG=false -e PRETTY_PRINT=true -e INDENT=2 "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}

@test "PRETTY_PRINT=true with INDENT=4 produces 4-space-indented output" {
    local expected actual
    expected=$(jq --indent 4 . <<< "${CANONICAL}")
    actual=$(printf '%s' "${INPUT}" | docker run -i --rm \
        -e DEBUG=false -e PRETTY_PRINT=true -e INDENT=4 "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}
