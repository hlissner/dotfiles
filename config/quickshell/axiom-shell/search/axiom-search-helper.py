#!/usr/bin/env python3
"""Small fixed-verb provider helper for Axiom Quickshell search."""

from __future__ import annotations

import ast
import configparser
import hashlib
import json
import math
import os
import subprocess
import sys
import urllib.parse
from pathlib import Path

MAX_ENTRIES = int(os.environ.get("AXIOM_CLIPBOARD_MAX_ENTRIES", "500"))
MAX_ENTRY_BYTES = int(os.environ.get("AXIOM_CLIPBOARD_MAX_ENTRY_BYTES", str(64 * 1024)))
CLIPBOARD_ENABLED = os.environ.get("AXIOM_CLIPBOARD_HISTORY", "1") != "0"
CLIPBOARD_BACKEND = os.environ.get("AXIOM_CLIPBOARD_BACKEND", "cliphist")
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
STATE_DIR = STATE_HOME / "axiom-shell"
CLIPBOARD_FILE = STATE_DIR / "clipboard-history.json"

EMOJI = [
    ("😀", "grinning face smile happy"),
    ("😂", "face with tears of joy laugh"),
    ("🥰", "smiling face hearts love"),
    ("😎", "smiling face sunglasses cool"),
    ("👍", "thumbs up yes ok"),
    ("🙏", "folded hands thanks please"),
    ("🔥", "fire hot lit"),
    ("✨", "sparkles magic"),
    ("✅", "check mark done success"),
    ("❌", "cross mark no fail"),
    ("⚠️", "warning caution"),
    ("❤️", "red heart love"),
    ("🚀", "rocket launch"),
    ("💡", "light bulb idea"),
    ("📋", "clipboard paste"),
    ("🔍", "magnifying glass search"),
    ("🏠", "house home"),
    ("📁", "folder files"),
    ("💻", "laptop computer"),
    ("🎮", "video game controller"),
]


def emit(value) -> int:
    print(json.dumps(value, ensure_ascii=False))
    return 0


def desktop_dirs() -> list[Path]:
    dirs = [Path.home() / ".local" / "share" / "applications"]
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    dirs.extend(Path(p) / "applications" for p in data_dirs.split(":"))
    return dirs


def parse_bool(value: str | None) -> bool:
    return str(value or "").lower() in {"1", "true", "yes"}


def scan_apps() -> dict[str, dict[str, str]]:
    apps: dict[str, dict[str, str]] = {}
    for directory in desktop_dirs():
        if not directory.exists():
            continue
        for path in sorted(directory.rglob("*.desktop")):
            desktop_id = path.relative_to(directory).as_posix().replace("/", "-")
            if desktop_id in apps:
                continue
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str
            try:
                parser.read(path, encoding="utf-8")
                entry = parser["Desktop Entry"]
            except Exception:
                continue
            if entry.get("Type", "Application") != "Application":
                continue
            if parse_bool(entry.get("NoDisplay")) or parse_bool(entry.get("Hidden")):
                continue
            name = entry.get("Name", "").strip()
            if not name:
                continue
            apps[desktop_id] = {
                "id": desktop_id,
                "provider": "app",
                "title": name,
                "subtitle": entry.get("Comment") or entry.get("GenericName") or desktop_id,
                "icon": entry.get("Icon", ""),
                "keywords": " ".join([desktop_id, entry.get("GenericName", ""), entry.get("Comment", ""), entry.get("Keywords", "")]),
            }
    return apps


def apps_list() -> int:
    return emit(list(scan_apps().values())[:300])


def app_launch(desktop_id: str) -> int:
    if desktop_id not in scan_apps():
        print(f"unknown desktop id: {desktop_id}", file=sys.stderr)
        return 2
    command = ["uwsm", "app", "--", "gtk-launch", desktop_id]
    try:
        subprocess.Popen(command, start_new_session=True)
    except FileNotFoundError:
        subprocess.Popen(["gtk-launch", desktop_id], start_new_session=True)
    return 0


def read_clipboard() -> list[dict[str, str]]:
    if CLIPBOARD_BACKEND == "cliphist":
        return read_cliphist()

    try:
        return json.loads(CLIPBOARD_FILE.read_text(encoding="utf-8"))
    except Exception:
        return []


def write_clipboard(entries: list[dict[str, str]]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    CLIPBOARD_FILE.write_text(json.dumps(entries[:MAX_ENTRIES], ensure_ascii=False), encoding="utf-8")


def cliphist_id(line: str) -> str:
    return "cliphist:" + hashlib.sha256(line.encode("utf-8", errors="replace")).hexdigest()[:16]


def read_cliphist() -> list[dict[str, str]]:
    try:
        cp = subprocess.run(["cliphist", "list"], text=True, capture_output=True, check=False)
    except FileNotFoundError:
        return []
    if cp.returncode != 0:
        return []

    entries = []
    for line in cp.stdout.splitlines()[:MAX_ENTRIES]:
        if not line:
            continue
        preview = line.split("\t", 1)[1] if "\t" in line else line
        entries.append({"id": cliphist_id(line), "text": preview[:MAX_ENTRY_BYTES], "cliphistLine": line})
    return entries


def clear_cliphist() -> int:
    try:
        return subprocess.run(["cliphist", "wipe"], check=False).returncode
    except FileNotFoundError:
        return 127


def copy_cliphist(entry_id: str) -> int:
    for entry in read_cliphist():
        if entry.get("id") != entry_id:
            continue
        try:
            decoded = subprocess.run(
                ["cliphist", "decode"],
                input=entry.get("cliphistLine", ""),
                text=True,
                capture_output=True,
                check=False,
            )
        except FileNotFoundError:
            return 127
        if decoded.returncode != 0:
            return decoded.returncode
        subprocess.run(["wl-copy"], input=decoded.stdout, text=True, check=False)
        return 0
    return 2


def clipboard_add() -> int:
    if not CLIPBOARD_ENABLED:
        return 0
    raw = sys.stdin.buffer.read(MAX_ENTRY_BYTES + 1)
    if not raw:
        return 0
    text = raw[:MAX_ENTRY_BYTES].decode("utf-8", errors="replace").strip("\0\n")
    if not text:
        return 0
    entries = [entry for entry in read_clipboard() if entry.get("text") != text]
    entries.insert(0, {"id": hashlib.sha256(text.encode("utf-8")).hexdigest()[:16], "text": text[:MAX_ENTRY_BYTES]})
    write_clipboard(entries)
    return 0


def clipboard_list() -> int:
    if not CLIPBOARD_ENABLED:
        return emit({"enabled": False, "items": []})
    return emit({"enabled": True, "items": read_clipboard()[:MAX_ENTRIES]})


def clipboard_clear() -> int:
    if CLIPBOARD_BACKEND == "cliphist":
        return clear_cliphist()

    write_clipboard([])
    return 0


def clipboard_copy(entry_id: str) -> int:
    if CLIPBOARD_BACKEND == "cliphist":
        return copy_cliphist(entry_id)

    for entry in read_clipboard():
        if entry.get("id") == entry_id:
            subprocess.run(["wl-copy"], input=entry.get("text", ""), text=True, check=False)
            return 0
    return 2


def copy_text(text: str) -> int:
    subprocess.run(["wl-copy"], input=text, text=True, check=False)
    return 0


ALLOWED_AST = (ast.Expression, ast.BinOp, ast.UnaryOp, ast.Constant, ast.Add, ast.Sub, ast.Mult, ast.Div, ast.FloorDiv, ast.Mod, ast.Pow, ast.USub, ast.UAdd, ast.Load)


def eval_node(node):
    if not isinstance(node, ALLOWED_AST):
        raise ValueError("unsupported expression")
    if isinstance(node, ast.Expression):
        return eval_node(node.body)
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return node.value
    if isinstance(node, ast.UnaryOp):
        value = eval_node(node.operand)
        return -value if isinstance(node.op, ast.USub) else value
    if isinstance(node, ast.BinOp):
        left = eval_node(node.left)
        right = eval_node(node.right)
        if isinstance(node.op, ast.Add): return left + right
        if isinstance(node.op, ast.Sub): return left - right
        if isinstance(node.op, ast.Mult): return left * right
        if isinstance(node.op, ast.Div): return left / right
        if isinstance(node.op, ast.FloorDiv): return left // right
        if isinstance(node.op, ast.Mod): return left % right
        if isinstance(node.op, ast.Pow): return math.pow(left, right)
    raise ValueError("unsupported expression")


def calc(expr: str) -> int:
    if len(expr) > 120 or not any(ch.isdigit() for ch in expr):
        return emit({"ok": False})
    if any(ch not in "0123456789.+-*/()% 	" for ch in expr):
        return emit({"ok": False})
    try:
        value = eval_node(ast.parse(expr, mode="eval"))
    except Exception:
        return emit({"ok": False})
    return emit({"ok": True, "result": (str(int(value)) if isinstance(value, float) and value.is_integer() else str(value))})


def emoji_list() -> int:
    return emit([{"id": e, "provider": "emoji", "title": e, "subtitle": words, "keywords": words} for e, words in EMOJI])


def web_url(query: str) -> int:
    return emit({"url": "https://duckduckgo.com/?q=" + urllib.parse.quote_plus(query)})


def main(argv: list[str]) -> int:
    if argv[:2] == ["apps", "list"]:
        return apps_list()
    if argv[:2] == ["apps", "launch"] and len(argv) == 3:
        return app_launch(argv[2])
    if argv[:2] == ["clipboard", "add"]:
        return clipboard_add()
    if argv[:2] == ["clipboard", "list"]:
        return clipboard_list()
    if argv[:2] == ["clipboard", "clear"]:
        return clipboard_clear()
    if argv[:2] == ["clipboard", "copy"] and len(argv) == 3:
        return clipboard_copy(argv[2])
    if argv[:1] == ["copy-text"] and len(argv) == 2:
        return copy_text(argv[1])
    if argv[:1] == ["calc"] and len(argv) == 2:
        return calc(argv[1])
    if argv[:2] == ["emoji", "list"]:
        return emoji_list()
    if argv[:1] == ["web-url"] and len(argv) == 2:
        return web_url(argv[1])
    print("usage: axiom-search-helper <apps|clipboard|copy-text|calc|emoji|web-url> ...", file=sys.stderr)
    return 64


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
