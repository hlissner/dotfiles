# Maintenance

## End4 Desktop Follow-Up

- `origin/master` still lacks the end4 `ii` source tree. Phase 1 must provide `config/quickshell/ii/shell.qml` and verify `systemctl --user restart quickshell.service` loads it before the full end4 desktop UX can be declared complete.
- Hyprland still has legacy `hyprland.pre.conf` generation. Phase 2 should move to end4-style source layering while keeping monitor/workspace/default-app facts in Nix.
- Matugen/wallpaper generated-state policy needs Phase 3 completion before generated Quickshell/Hyprland/hyprlock/fuzzel/terminal colors are relied on.
- `cliphist` backend is wired, but database retention pruning is not implemented. Define retention, clear UX, and disable behavior against the end4 `ii` clipboard/search surface.
- Live Axiom validation remains required for sidebars, overview, launcher, control center, notification center, OSD, power profiles, brightness/DDC, NetworkManager, Bluetooth, tray, and polkit prompts.
