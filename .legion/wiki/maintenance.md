# Maintenance

## End4 Desktop Follow-Up

- Live Axiom validation remains required inside the actual Hyprland session: restart `quickshell.service`, confirm the `org.kde.kirigami` load failure is gone, verify `Super+Space`, `Super+A`, and Colemak behavior, and exercise sidebars, overview/search, notifications, OSD, lock/session, wallpaper switching, polkit prompts, tray, audio, brightness/DDC, NetworkManager, Bluetooth, and power profiles.
- `cliphist` backend is wired, but database retention pruning is not implemented. Define retention, clear UX, and disable behavior against the end4 `ii` clipboard/search surface.
- Imported AI/cloud/function tooling is present as part of upstream `ii`. Harden default policy/documentation before broader enablement and keep API-key behavior inert without explicit user configuration.
- Map or hide upstream optional commands that still assume KDE tools, `kitty`/`fish`, Arch-style package updates, or other non-Axiom defaults.
- Track future Quickshell package updates carefully because imported `ii` currently requires `Quickshell.Services.Polkit`; pinned `0.2.1` is insufficient and the local wrapper builds `0.3.0`.
