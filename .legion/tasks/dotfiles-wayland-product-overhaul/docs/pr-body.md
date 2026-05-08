## Summary

- Replace the old Linux desktop baseline with a Hyprland + UWSM + DMS/Quickshell product path, including portals, Matugen hooks, and product window/control rules.
- Move workstation defaults to Zen (`zen-beta`), scoped mpv, Vesktop/Discord, Steam Gamescope/Gamemode/Umu tuning, NetworkManager+iwd+resolved Wi-Fi, and BlueZ/Blueman reliability settings.
- Remove obsolete X11/bspwm/sxhkd/Waybar/Dunst/idle/browser/media/Spotify/Spicetify paths while preserving the Darwin shared-module boundary.

## Verification

- `nix flake show --impure --all-systems`
- `nix eval --impure .#nixosConfigurations.{ramen,harusame,udon,azar,atlas,axiom}.config.system.name`
- Key option checks for Zen package/default/MIME/class, Hyprland UWSM, DMS service, portals, NetworkManager, Bluetooth, Steam, mpv, and Vesktop config.
- Legacy source searches for removed desktop/browser/media/Spotify paths in active Nix modules and Hyprland config.
- Darwin leakage search in `darwin/*.nix`.
- `git diff --check`

## Deferred / Blocked

- `nix build --impure --dry-run .#nixosConfigurations.ramen.config.system.build.toplevel` is blocked locally by the pre-existing agenix assertion: no `/etc/ssh/host_ed25519`.
- Manual runtime checks for Hyprland/UWSM, DMS, portals/screenshare, Wi-Fi, Bluetooth, Steam, and mpv are deferred.
- Darwin runtime/build validation is deferred to a Darwin machine.

## Evidence Docs

- `.legion/tasks/dotfiles-wayland-product-overhaul/docs/test-report.md`
- `.legion/tasks/dotfiles-wayland-product-overhaul/docs/review-change.md`
- `.legion/tasks/dotfiles-wayland-product-overhaul/docs/report-walkthrough.md`
