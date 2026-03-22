#!/usr/bin/env python3

"""
canonicalize_json.py: Canonicalize JSON per JCS (RFC 8785).

A containerized `JCS (RFC 8785) <https://datatracker.ietf.org/doc/html/rfc8785>`_
compliant JSON formatter, utilizing the `Python JCS <https://pypi.org/project/jcs>`_
library authored by `Anders Rundgren <https://github.com/cyberphone>`_.

Copyright (C) 2025–2026 James Hanlon [mailto:jim@hanlonsoftware.com]
SPDX-License-Identifier: AGPL-3.0-or-later

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""

__author__ = 'Jim Hanlon <mailto:jim@hanlonsoftware.com>'
__copyright__ = 'Copyright (c) 2025–2026, James Hanlon'
__credits__ = ['Jim Hanlon', 'Anders Rundgren (jcs library)']
__license__ = 'AGPL-3.0-or-later'
# __version__ reflects the container's APP_VERSION env var injected at build
# time.  When run outside a container the fallback is the literal string
# "unknown" so that imports in unit-test contexts do not error.
__version__ = __import__('os').environ.get('APP_VERSION', 'unknown')
__maintainer__ = 'Jim Hanlon'
__email__ = 'jim@hanlonsoftware.com'
__status__ = 'Production'

from sys import stdin, stderr, exit as sys_exit
from json import JSONDecodeError, load
from jcs import canonicalize


def _fail(message: str) -> None:
    """Write *message* to stderr and exit with status 1."""
    stderr.write(f"{message}\n")
    sys_exit(1)


def main() -> None:
    """Read JSON from stdin, canonicalize per JCS (RFC 8785), and print to stdout."""
    try:
        data = load(stdin)
    except JSONDecodeError as exc:
        _fail(f"Invalid JSON input: {exc}")

    try:
        output = canonicalize(data).decode('utf-8')
    except (TypeError, ValueError) as exc:
        # jcs.canonicalize raises TypeError for unsupported Python types and
        # ValueError for numeric values not representable in JSON (e.g., NaN,
        # Infinity).  json.load already constrains input to safe types, but we
        # guard here in case jcs behaviour changes across versions.
        _fail(f"Canonicalization failed: {exc}")

    print(output, flush=True)


if __name__ == '__main__':
    main()
