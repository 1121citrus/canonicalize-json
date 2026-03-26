#!/usr/bin/env bats
# test/02-canonicalize.bats — test canonicalize-json canonicalize mode.
#
# Copyright (C) 2025 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    IMAGE="${IMAGE:-1121citrus/canonicalize-json:latest}"
    export IMAGE
}

@test "sorts nested object keys" {
    local input='{"z":{"dec":"122","hex":"7A","oct":"172"},"1":{"hex":"31","oct":"61","dec":"49"},"A":{"hex":"41", "dec":"65","oct":"101"}}'
    local expected='{"1":{"dec":"49","hex":"31","oct":"61"},"A":{"dec":"65","hex":"41","oct":"101"},"z":{"dec":"122","hex":"7A","oct":"172"}}'
    local actual
    actual=$(printf '%s' "${input}" | docker run -i --rm -e DEBUG=false "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}

@test "preserves primitives and arrays" {
    local input='{"b":true,"a":null,"c":[3,2,1],"d":"text"}'
    local expected='{"a":null,"b":true,"c":[3,2,1],"d":"text"}'
    local actual
    actual=$(printf '%s' "${input}" | docker run -i --rm -e DEBUG=false "${IMAGE}")
    echo "expected: ${expected}"
    echo "     got: ${actual}"
    [ "${actual}" = "${expected}" ]
}

@test "rejects invalid JSON with non-zero exit and error message" {
    local input='{"a":}'
    local actual
    local status
    actual=$(printf '%s' "${input}" | docker run -i --rm -e DEBUG=false "${IMAGE}" 2>&1) && status=0 || status=$?
    echo "status: ${status}"
    echo "output: ${actual}"
    [ "${status}" -ne 0 ]
    [[ "${actual}" == *"Invalid JSON input"* ]]
}
