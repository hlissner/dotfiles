# Axiom Desktop Guide

This desktop is an Isabel-first Hyprland + Quickshell setup. The visible side dock is the primary GUI entry point; shortcuts are optional accelerators you can learn gradually.

## Visible Shell

- `NIX` opens this guide.
- `1` through `9` switch workspaces.
- `ZEN`, `TERM`, `FILES`, `CHAT`, and `GAME` open the browser, terminal, file manager, Vesktop, and Steam.
- `APP` opens the graphical app launcher.
- `WIFI`, `BT`, and `VOL` open NetworkManager, Blueman, and Pavucontrol.
- `SHOT` starts the screenshot flow.
- `REC` starts screen recording.
- `LOCK` locks the session.
- `PWR` opens the power menu.
- `NOTE` shows notification status; incoming desktop notifications increment the counter.

## First Shortcuts To Learn

| Shortcut | Action |
|---|---|
| `Super` + `Space` | App launcher |
| `Super` + `B` | Browser |
| `Super` + `E` | File manager |
| `Super` + `Return` | Terminal |
| `Print` | Screenshot |
| `Super` + `/` | This guide |
| `Super` + `Shift` + `Q` | Power menu |

## Window Basics

- `Super` + left mouse drag moves windows.
- `Super` + right mouse drag resizes windows.
- `Super` + `F` toggles floating mode.
- `Super` + `Shift` + `F` toggles fullscreen.
- `Super` + number switches workspaces.
- `Super` + `Shift` + number moves the active window to a workspace.

## Troubleshooting

- Restart the shell with `systemctl --user restart quickshell.service`.
- View shell logs with `journalctl --user -u quickshell.service -b`.
- Reload Hyprland config with `Super` + `R`.
- If the shell does not appear, open a terminal with `Super` + `Return` and restart `hyprland-session.target` with `systemctl --user restart hyprland-session.target`.

## Design Intent

The desktop should feel like a coherent personal computer first and a tiling WM second. GUI controls are visible by default; shortcuts are there to make repeated actions faster after you are comfortable.
