# Maintenance

## Terminal Follow-Up

- Foot terminal notification behavior was disabled by removing unsupported `[main].notify` from the global config. If terminal notification behavior is still desired, restore it only through a Foot 1.25-supported option or an explicit external wrapper design validated with `foot --check-config`.

## End4 Desktop Follow-Up

- Live Axiom validation remains required inside the actual Hyprland session: restart `quickshell.service`, confirm the `org.kde.kirigami` load failure is gone, verify `Super+Space` typing, `Super+A`, and Colemak behavior, and exercise sidebars, overview/search, notifications, OSD, lock/session, preset wallpaper/theme switching, screenshot/image previews, dock far-left placement, polkit prompts, tray, audio, brightness/DDC, NetworkManager, Bluetooth, and power profiles.
- `cliphist` backend is wired, but database retention pruning is not implemented. Define retention, clear UX, and disable behavior against the end4 `ii` clipboard/search surface.
- Imported AI/cloud/function tooling is present as part of upstream `ii`. Harden default policy/documentation before broader enablement and keep API-key behavior inert without explicit user configuration.
- Map or hide upstream optional commands that still assume KDE tools, `kitty`/`fish`, Arch-style package updates, or other non-Axiom defaults.
- Track future Quickshell package updates carefully because imported `ii` currently requires `Quickshell.Services.Polkit`; pinned `0.2.1` is insufficient and the local wrapper builds `0.3.0`.
