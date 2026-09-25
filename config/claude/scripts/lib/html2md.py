# html2md.py SRC DEST -- convert every *.html under SRC into markdown at the
# same relative path under DEST. Only the content element survives; the
# navigation, search boxes and inline SVGs around it are most of the bytes and
# none of the answers.

import os, re, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

# For Hugo and mdBook
SELECTORS = ('<div class="content">', '<main id="content"', '<main')

def extract(html):
    for sel in SELECTORS:
        i = html.find(sel)
        if i >= 0:
            end = "</main>" if sel.startswith("<main") else "</div>"
            j = html.rfind(end)
            if j > i:
                return html[i:j]
    return None

def convert(src, dst):
    html = open(src, encoding="utf-8", errors="replace").read()
    # Hextra answers a bad URL with an 404 page but HTTP 200
    if "hextra-error" in html:
        return "soft 404: %s" % src
    body = extract(html)
    if body is None:
        return "no content element: %s" % src
    body = re.sub(r"<(script|style|svg)\b.*?</\1>", "", body, flags=re.S)
    body = re.sub(r'<img[^>]*src="data:[^"]*"[^>]*>', "", body)
    body = re.sub(r"<button\b.*?</button>", "", body, flags=re.S)
    md = subprocess.run(
        ["pandoc", "-f", "html", "-t", "gfm-raw_html", "--wrap=none"],
        input=body, capture_output=True, text=True, check=True).stdout
    # Hugo hangs an empty self-links and pandoc faithfully renders it as
    # `[](#the-heading)`
    md = re.sub(r"\s*\[\]\(#[^)]*\)", "", md)
    md = re.sub(r"\n{3,}", "\n\n", md).strip() + "\n"
    if len(md) < 32:
        return "empty after conversion: %s" % src
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    open(dst, "w", encoding="utf-8").write(md)
    return None

def attempt(job):
    try:
        return convert(*job)
    except (subprocess.CalledProcessError, OSError) as e:
        return "%s: %s" % (job[0], e)

def main(src, dest):
    jobs = []
    for root, _, files in os.walk(src):
        for f in files:
            if f.endswith(".html"):
                path = os.path.join(root, f)
                rel = os.path.relpath(path, src)[:-len(".html")] + ".md"
                jobs.append((path, os.path.join(dest, rel)))
    # pandoc is the slow part and a subprocess, so threads are enough
    with ThreadPoolExecutor(os.cpu_count() or 4) as pool:
        errors = [e for e in pool.map(attempt, jobs) if e]
    for e in errors:
        print(e, file=sys.stderr)
    if len(errors) == len(jobs):
        print("converted zero pages -- upstream markup moved?", file=sys.stderr)
        return 1
    return 0

sys.exit(main(sys.argv[1], sys.argv[2]))
