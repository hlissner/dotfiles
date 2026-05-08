# Implementation Plan: Wayland Product Overhaul

## Milestone 1: Boundaries and Removals

- Remove/update references to X11/bspwm/sxhkd, Dunst, Waybar, old idle services, non-Zen browser baselines, broad media modules, and Spotify/Spicetify.
- Keep no backward-compatibility aliases for removed desktop paths.
- Confirm Darwin imports remain shared-safe.

## Milestone 2: Hyprland, UWSM, DMS/Quickshell, Portals, Matugen

- Switch Hyprland to UWSM and greetd direct command.
- Wire DMS/Quickshell and Matugen template surfaces.
- Replace Mako/Waybar shell assumptions with DMS controls.
- Configure Hyprland portal with GTK fallback.

## Milestone 3: Zen, mpv, Discord

- Resolve Zen source; use a narrow flake input because pinned nixpkgs lacks Zen.
- Configure Zen as default browser and URL handler.
- Keep media scope to mpv and Discord/Vesktop.
- Generate mpv and Vesktop config under XDG paths.

## Milestone 4: Steam, Wi-Fi, Bluetooth

- Add Gamescope session, Umu launcher, Mangohud, Gamemode hooks, fake HOME/NTFS behavior, NOFILE tuning, and relevant sysctls.
- Scope NetworkManager+iwd+resolved to workstation Wi-Fi hardware.
- Add BlueZ reliability settings, `btusb`, Blueman fallback, and resume reset.

## Milestone 5: Verification and PR Evidence

- Evaluate retained NixOS hosts and key options.
- Run flake output enumeration.
- Dry-run a workstation build and document blockers.
- Search for removed legacy references.
- Record Darwin boundary evidence and deferred Darwin-machine validation.
