# Report Walkthrough: Wayland Product Overhaul

> Mode: implementation

## Reviewer Path

1. Start with the removals: legacy X11/bspwm/sxhkd, Waybar, Dunst, old idle services, old browser modules, Spotify/Spicetify, broad media modules, and stale theme/config files were removed rather than shimmed.
2. Review the new Wayland shell spine: `modules/desktop/hyprland.nix` enables UWSM, greetd, portals, DMS/Quickshell, Matugen hooks, product window rules, and DMS control entries.
3. Review product apps: Zen is the browser baseline through the narrow `zen-browser` flake input, mpv is the scoped media player, and Discord uses Vesktop with XDG settings.
4. Review reliability/gaming changes: Steam gained Gamescope/Gamemode/Mangohud/Umu and workstation sysctls; Wi-Fi moved to NetworkManager+iwd+resolved for workstation Wi-Fi profiles; Bluetooth gained BlueZ reliability settings and Blueman fallback.
5. Review Darwin boundary: Darwin imports were not expanded with Linux desktop/system modules, and static Darwin leakage searches passed.

## Evidence

- Design source: `docs/rfc.md`; RFC review PASS: `docs/review-rfc.md`.
- Verification evidence: `docs/test-report.md`.
- Readiness review: `docs/review-change.md` PASS.
- Implementation notes: `docs/implementation-notes.md`.

## Important Review Notes

- Git flake validation required marking new modules intent-to-add before Nix could evaluate them; the final commit will track those files normally.
- Zen integration was corrected to use the selected package's `zen-beta` executable, `zen-beta.desktop` MIME ID, and `zen-beta` Hyprland class.
- `xwaylandvideobridge` was removed from the Discord module because the pinned unstable alias is no longer usable; screen sharing relies on Vesktop plus the configured portal path.
- `axiom` dry-run caught build-time issues that plain evaluation missed; NetworkManager INI keys, the removed `nm-connection-editor` package attribute, the removed `rofi-wayland-unwrapped` package, and Steam `vm.max_map_count` priority were corrected.

## Residual Risks

- Full `ramen` toplevel dry-run is locally blocked by the pre-existing agenix host-key assertion for `/etc/ssh/host_ed25519`; `axiom` toplevel dry-run passes.
- Manual runtime checks remain deferred: Hyprland/UWSM startup, DMS UI, portals/screenshare, Wi-Fi roaming, Bluetooth pairing, Steam launch, and mpv playback.
- Darwin build/runtime validation remains deferred to a Darwin machine per task contract.
