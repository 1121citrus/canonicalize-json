#!/usr/bin/env python

"""canonicalize-json.py: Canonicalize JSON per [JCS (RFC 8785)](https://datatracker.ietf.org/doc/html/rfc8785)."""

__author__      = 'Jim Hanlon <mailto:jim@hanlonsoftware.com>'
__copyright__   = 'Copyright (c) 2025, James Hanlon'
__credits__ = ['Jim Hanlon']
__license__ = 'GPLv3'
__version__ = '0.1'
__maintainer__ = 'Jim Hanlon'
__email__ = 'jim@hanlonsoftware.com'
__status__ = 'Production'

from jcs import canonicalize
from json import dump, load
from sys import stdin, stdout

print(canonicalize(load(stdin)).decode('utf-8'), flush=True)

