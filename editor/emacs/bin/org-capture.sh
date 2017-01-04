#!/usr/bin/env bash
emacsclient -c -F "((name . \"org-capture\") (height . 15) (width . 80))" --eval "(org-capture nil \"${1:-n}\")"
