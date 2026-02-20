#!/usr/bin/env python

"""
canonicalize-json.py: Canonicalize JSON per JCS (RFC 8785).

A containerized [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785)
compliant JSON formatter, utilizing the Python JCS library.

Copyright (C) 2025 James Hanlon [mailto:jim@hanlonsoftware.com]

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

__author__      = 'Jim Hanlon <mailto:jim@hanlonsoftware.com>'
__copyright__   = 'Copyright (c) 2025, James Hanlon'
__credits__ = ['Jim Hanlon']
__license__ = 'AGPLv3'
__version__ = '0.1'
__maintainer__ = 'Jim Hanlon'
__email__ = 'jim@hanlonsoftware.com'
__status__ = 'Production'

from sys import stdin, stderr, exit as sys_exit
from json import JSONDecodeError, load
from jcs import canonicalize

def _fail(message: str) -> None:
	stderr.write(f"{message}\n")
	sys_exit(1)


def main() -> None:
	try:
		data = load(stdin)
	except JSONDecodeError as exc:
		_fail(f"Invalid JSON input: {exc}")

	try:
		output = canonicalize(data).decode('utf-8')
	except Exception as exc:  # jcs raises generic exceptions
		_fail(f"Canonicalization failed: {exc}")

	print(output, flush=True)


if __name__ == '__main__':
	main()
