# RFC: Wayland Product Overhaul Architecture

> Status: approved for implementation
> Date: 2026-05-08

## Decision

Refactor the Linux workstation desktop into a Wayland-first Hyprland + UWSM + DMS/Quickshell product, using Zen as the primary browser, mpv and Discord/Vesktop as the scoped media/chat surface, NetworkManager+iwd+resolved for workstation Wi-Fi, BlueZ/Blueman reliability settings for Bluetooth, and hlissner-style Steam/Gamescope/Gamemode/Umu tuning.

Darwin remains a shared shell/dev/editor/XDG target only. This task avoids Linux-only leakage into Darwin imports but does not implement Darwin desktop behavior.

## Goals

- Adopt the hlissner architecture spine: explicit modules, UWSM, DMS/Quickshell, Matugen, and Steam/workstation tuning.
- Apply Isabel product guidance selectively: portals, app rules, mpv defaults, Discord settings, NetworkManager+iwd, BlueZ reliability, and cohesive MIME/default-app behavior.
- Remove obsolete X11/bspwm/sxhkd/Polybar/Dunst/Waybar/idle-service paths instead of adding compatibility shims.
- Make Zen the browser baseline through nixpkgs if available, otherwise through a narrow flake input.
- Keep multimedia scope limited to mpv and Discord/Vesktop.

## Non-Goals

- No backwards compatibility for the old Linux desktop stack.
- No Secure Boot enablement.
- No broad multimedia expansion beyond mpv and Discord.
- No import of Isabel's full framework or hlissner's full repository structure.
- No Darwin Hyprland, Quickshell, Steam, NetworkManager, or BlueZ target.

## Implementation Shape

- Remove old desktop/service/browser/media modules and update retained host references in the same PR.
- Enable Hyprland with `programs.hyprland.withUWSM = true`, systemd path integration, Hyprland portal plus GTK fallback, and greetd launching through UWSM.
- Enable DMS/Quickshell as the shell/control layer with Matugen template wiring.
- Add Zen browser module and default URL/MIME integration.
- Add mpv-focused video module and Discord/Vesktop settings.
- Add Steam Gamescope session, Gamemode hooks, Mangohud, Umu launcher, fake HOME/NTFS behavior, and NOFILE/sysctl tuning.
- Scope NetworkManager+iwd+resolved to workstation Wi-Fi profiles and keep non-workstation hosts out of that ownership change.
- Add BlueZ reliability settings, `btusb`, and Blueman manager fallback without forcing hlissner's hardware-specific `ControllerMode=bredr` default.

## Verification Requirements

- Enumerate flake outputs with `nix flake show --impure --all-systems`.
- Evaluate retained Linux NixOS hosts.
- Dry-run or build at least one workstation toplevel; record environmental blockers.
- Check key options for Zen, UWSM, DMS/Quickshell, portals, mpv, Discord, Steam, Wi-Fi, and Bluetooth.
- Search for removed legacy references in active Nix modules and desktop config.
- Search Darwin imports for Linux-only desktop/system leakage and defer concrete Darwin build/runtime validation to a Darwin machine.

## Rollback

- Preferred rollback is reverting the one PR before merge.
- During branch work, revert the milestone commit that introduced a failing subsystem.
- On real hardware, use the previous NixOS generation or `nixos-rebuild switch --rollback`.
- No data migration is required; runtime config directories for Zen, Vesktop, mpv, DMS, or Matugen may remain after testing.
