#!/usr/bin/env bash
emacsclient -c -F "((name . \"org-capture\") (height . 25) (width . 70))" --eval "(org-capture nil \"${1:-n}\")"
