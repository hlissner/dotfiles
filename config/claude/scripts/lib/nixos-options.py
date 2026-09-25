# nixos-options.py OPTIONS_JSON OUT -- one line per option, as
# `name :: type :: default :: first sentence`, so it can be grepped instead of
# jq'ing tens of megabytes.

import json, re, sys

opts = json.load(open(sys.argv[1]))

def flat(v):
    # Defaults and examples arrive as {_type, text} literals as often
    # as plain values; both want to end up on one line.
    if isinstance(v, dict):
        v = v.get("text", v.get("value", ""))
    return re.sub(r"\s+", " ", str(v)).strip()

def first_sentence(desc):
    d = re.sub(r"\s+", " ", desc or "").strip()
    m = re.match(r"(.+?[.!?])(\s|$)", d)
    return (m.group(1) if m else d)[:240]

with open(sys.argv[2], "w") as fd:
    for name in sorted(opts):
        o = opts[name]
        fd.write("%s :: %s :: %s :: %s\n" % (
            name,
            flat(o.get("type", ""))[:80] or "?",
            flat(o.get("default", ""))[:80] or "-",
            first_sentence(o.get("description", ""))))
