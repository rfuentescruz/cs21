#!/usr/bin/env python

import sys

while True:
    pairs = raw_input()
    if not pairs:
        sys.exit()
    pairs = pairs.split()
    print '.word 0x00%02X%02X%02X   # %s' % (
        int(pairs[0]),
        int(pairs[1]) if len(pairs) > 1 else 255,
        int(pairs[2]) if len(pairs) > 2 else 255,
        pairs
    )
