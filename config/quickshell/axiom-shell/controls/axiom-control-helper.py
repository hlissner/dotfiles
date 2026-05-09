#!/usr/bin/env python3
"""Fixed-verb quick controls helper for Axiom Quickshell."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any


def run(argv: list[str], timeout: float = 2.0) -> subprocess.CompletedProcess[str]:
    return subprocess.run(argv, text=True, capture_output=True, timeout=timeout, check=False)


def have(name: str) -> bool:
    return shutil.which(name) is not None


def out(argv: list[str], fallback: str = "") -> str:
    if not have(argv[0]):
      return fallback
    try:
        cp = run(argv)
    except Exception:
        return fallback
    return cp.stdout.strip() if cp.returncode == 0 else fallback


def volume_status(source: bool = False) -> dict[str, Any]:
    if not have("pamixer"):
        return {"available": False, "label": "pamixer unavailable"}
    prefix = ["pamixer"] + (["--default-source"] if source else [])
    volume = out(prefix + ["--get-volume"], "0")
    muted = out(prefix + ["--get-mute"], "false") == "true"
    label = f"{volume}%" + (" muted" if muted else "")
    return {"available": True, "volume": int(volume or 0), "muted": muted, "label": label}


def network_status() -> dict[str, Any]:
    if not have("nmcli"):
        return {"available": False, "state": "nmcli unavailable", "primary": "Open NetworkManager editor"}
    state = out(["nmcli", "-t", "-f", "STATE", "general"], "unknown")
    active = out(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"])
    primary = active.splitlines()[0].replace(":", " on ") if active else "No active connection"
    return {"available": True, "state": state, "primary": primary}


def bluetooth_status() -> dict[str, Any]:
    if not have("bluetoothctl"):
        return {"available": False, "powered": "bluetoothctl unavailable", "connected": []}
    show = out(["bluetoothctl", "show"])
    powered = "Powered: yes" in show
    devices = []
    paired = out(["bluetoothctl", "devices", "Connected"])
    for line in paired.splitlines():
        parts = line.split(" ", 2)
        if len(parts) == 3:
            devices.append(parts[2])
    return {"available": True, "powered": powered, "connected": devices}


def media_status() -> dict[str, Any]:
    if not have("playerctl"):
        return {"available": False, "player": "playerctl unavailable", "summary": "No active player", "status": "unavailable"}
    fmt = "{{playerName}}\t{{status}}\t{{title}}\t{{artist}}"
    line = out(["playerctl", "metadata", "--format", fmt])
    if not line:
        return {"available": True, "player": "No active player", "summary": "No active player", "status": "Stopped"}
    player, status, title, artist = (line.split("\t") + ["", "", "", ""])[:4]
    summary = title if not artist else f"{title} — {artist}"
    return {"available": True, "player": player, "status": status, "title": title, "artist": artist, "summary": summary or status}


def brightness_status() -> dict[str, Any]:
    if not have("brightnessctl"):
        return {"available": False, "label": "brightnessctl unavailable", "percent": 0}
    raw = out(["brightnessctl", "-m"], "")
    parts = raw.split(",")
    if len(parts) >= 4:
        percent = parts[3].strip().rstrip("%")
        try:
            value = int(percent)
        except ValueError:
            value = 0
        return {"available": True, "label": f"{value}%", "percent": value, "device": parts[0]}
    return {"available": True, "label": out(["brightnessctl", "get"], "unknown"), "percent": 0}


def power_status() -> dict[str, Any]:
    if not have("powerprofilesctl"):
        return {"available": False, "profile": "powerprofilesctl unavailable"}
    profile = out(["powerprofilesctl", "get"], "unknown")
    return {"available": True, "profile": profile}


def resource_status() -> dict[str, Any]:
    try:
        load = " ".join(Path("/proc/loadavg").read_text(encoding="utf-8").split()[:3])
    except Exception:
        load = "unknown"
    try:
        meminfo = {}
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            key, value = line.split(":", 1)
            meminfo[key] = int(value.strip().split()[0])
        total = meminfo.get("MemTotal", 0)
        available = meminfo.get("MemAvailable", 0)
        used = max(total - available, 0)
        memory = f"{used // 1024} MiB / {total // 1024} MiB" if total else "unknown"
    except Exception:
        memory = "unknown"
    return {"available": True, "load": load, "memory": memory}


def status() -> None:
    print(json.dumps({
        "audio": {"output": volume_status(False), "input": volume_status(True)},
        "network": network_status(),
        "bluetooth": bluetooth_status(),
        "media": media_status(),
        "brightness": brightness_status(),
        "power": power_status(),
        "resources": resource_status(),
    }))


def ipc_osd(kind: str, label: str, value: str, detail: str = "") -> None:
    if not have("quickshell"):
        return
    try:
        run(["quickshell", "ipc", "-c", "axiom-shell", "call", "axiom", "showOsd", kind, label, value, detail], timeout=1.0)
    except Exception:
        pass


def audio(args: list[str]) -> int:
    if len(args) != 2 or args[0] not in {"output-volume", "input-volume"} or args[1] not in {"+10", "-10", "mute"}:
        return usage()
    if not have("pamixer"):
        return 127
    prefix = ["pamixer"] + (["--default-source"] if args[0] == "input-volume" else [])
    if args[1] == "mute":
        cp = run(prefix + ["-t"])
    elif args[1].startswith("+"):
        cp = run(prefix + ["-i", args[1][1:]])
    else:
        cp = run(prefix + ["-d", args[1][1:]])
    snap = volume_status(args[0] == "input-volume")
    ipc_osd("mic" if args[0] == "input-volume" else "volume", snap.get("label", "Audio"), str(snap.get("volume", 0)), "Axiom quick controls")
    return cp.returncode


def network(args: list[str]) -> int:
    if args != ["wifi-toggle"]:
        return usage()
    if not have("nmcli"):
        return 127
    state = out(["nmcli", "radio", "wifi"], "disabled")
    return run(["nmcli", "radio", "wifi", "off" if state == "enabled" else "on"]).returncode


def bluetooth(args: list[str]) -> int:
    if args != ["power-toggle"]:
        return usage()
    if not have("bluetoothctl"):
        return 127
    powered = bluetooth_status().get("powered") is True
    return run(["bluetoothctl", "power", "off" if powered else "on"]).returncode


def media(args: list[str]) -> int:
    verbs = {
        "play-pause": ["playerctl", "play-pause"],
        "next": ["playerctl", "next"],
        "previous": ["playerctl", "previous"],
        "seek-forward": ["playerctl", "position", "5+"],
        "seek-back": ["playerctl", "position", "5-"],
    }
    if len(args) != 1 or args[0] not in verbs:
        return usage()
    if not have("playerctl"):
        return 127
    cp = run(verbs[args[0]])
    snap = media_status()
    ipc_osd("media", snap.get("summary", args[0]), "100", f"{snap.get('player', '')} {snap.get('status', '')}".strip())
    return cp.returncode


def brightness(args: list[str]) -> int:
    verbs = {
        "up": ["brightnessctl", "set", "10%+"],
        "down": ["brightnessctl", "set", "10%-"],
    }
    if len(args) != 1 or args[0] not in verbs:
        return usage()
    if not have("brightnessctl"):
        return 127
    cp = run(verbs[args[0]])
    snap = brightness_status()
    ipc_osd("brightness", snap.get("label", "Brightness"), str(snap.get("percent", 0)), snap.get("device", ""))
    return cp.returncode


def power(args: list[str]) -> int:
    if len(args) != 2 or args[0] != "profile" or args[1] not in {"power-saver", "balanced", "performance"}:
        return usage()
    if not have("powerprofilesctl"):
        return 127
    cp = run(["powerprofilesctl", "set", args[1]])
    ipc_osd("power", args[1], "100", "Power profile")
    return cp.returncode


def session(args: list[str]) -> int:
    verbs = {
        "lock": ["hey", ".lock"],
        "dpms-off": ["hyprctl", "dispatch", "dpms", "off"],
        "wlogout": ["wlogout"],
    }
    if len(args) != 1 or args[0] not in verbs:
        return usage()
    return run(verbs[args[0]]).returncode


def usage() -> int:
    print("usage: axiom-control-helper status|audio|network|bluetooth|media|brightness|power|session ...", file=sys.stderr)
    return 2


def main(argv: list[str]) -> int:
    if argv == ["status"]:
        status()
        return 0
    if not argv:
        return usage()
    group, rest = argv[0], argv[1:]
    if group == "audio":
        return audio(rest)
    if group == "network":
        return network(rest)
    if group == "bluetooth":
        return bluetooth(rest)
    if group == "media":
        return media(rest)
    if group == "brightness":
        return brightness(rest)
    if group == "power":
        return power(rest)
    if group == "session":
        return session(rest)
    return usage()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
