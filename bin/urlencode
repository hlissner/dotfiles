#!/usr/bin/env python
import os, sys, urllib
if os.isatty(file.fileno(sys.stdin)):
    text = sys.argv[1]
else:
    text = "".join(sys.stdin.readlines())
print(urllib.quote_plus(text.strip()))
