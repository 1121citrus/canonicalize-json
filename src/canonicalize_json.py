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
__license__ = 'GPLv3'
__version__ = '0.1'
__maintainer__ = 'Jim Hanlon'
__email__ = 'jim@hanlonsoftware.com'
__status__ = 'Production'

from sys import stdin
from json import load
from jcs import canonicalize

print(canonicalize(load(stdin)).decode('utf-8'), flush=True)
