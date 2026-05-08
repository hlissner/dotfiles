# Research: Dotfiles Wayland Product Overhaul

## Current Repo Findings

- Darwin imports are curated under `darwin/default.nix` and do not import `modules/desktop/**`; Linux desktop changes must keep that boundary intact.
- Existing Linux desktop code contained legacy X11/bspwm, Waybar, Dunst, old idle services, old browser modules, broad media modules, and systemd-networkd/wpa_supplicant workstation Wi-Fi ownership.
- The repository convention is to keep options under `modules.*`, use `user.packages`, `home.configFile`, `home.file`, `XDG_FAKE_HOME`, and `hey.info` metadata.
- `_module.check = false` means unknown `modules.*` references can evaluate silently, so validation must check that new module options are actually present.

## hlissner Evidence

- Reference repo: `/tmp/opencode/hlissner-dotfiles.ZqBHWc`, commit `1b4383a`.
- Useful direction: UWSM Hyprland, DMS shell, Quickshell package wiring, Matugen templates, DMS notification/audio/color commands, Steam Gamescope/Gamemode/Umu tuning, workstation sysctls, and XDG discipline.
- Needs adaptation: hlissner removed Darwin entirely, while this repo must retain Darwin outputs and Linux-only boundaries.

## Isabel Evidence

- Reference repo: `/tmp/opencode/isabelroses-dotfiles.IafITY`, commit `cf42f00`.
- Useful product details: Quickshell dependency wrapping, system-owned portals with GTK fallback, Chromium browser product concepts to translate to Zen, Discord/Vesktop privacy/screen-share concepts, mpv `gpu-next`/Vulkan/MPRIS direction, NetworkManager+iwd+resolved, BlueZ reliability, and consistent MIME/default-app handling.
- Avoid direct copy of Isabel's full framework, full Moonlight extension list, or Chromium baseline.

## Key Risks

- One large PR mixes removals, shell replacement, app defaults, networking, Bluetooth, Steam, and Darwin boundaries.
- Zen and DMS package availability must be verified in this flake.
- Git flakes do not evaluate untracked new modules reliably; new module files need to be tracked or marked intent-to-add before validation.
- Switching Wi-Fi ownership too broadly could affect non-workstation/server hosts.
- Darwin can regress if shared modules gain unguarded Linux-only options.
