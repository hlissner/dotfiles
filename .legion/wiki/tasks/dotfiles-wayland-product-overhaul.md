# Dotfiles Wayland Product Overhaul

Status: PR-ready implementation handoff
Task: `.legion/tasks/dotfiles-wayland-product-overhaul/`
Branch: `legion/dotfiles-wayland-product-overhaul`

## Summary

Refactored Linux workstation dotfiles to a Wayland-first product stack centered on Hyprland + UWSM + DMS/Quickshell, Zen, mpv, Vesktop/Discord, Steam tuning, NetworkManager+iwd+resolved Wi-Fi, and BlueZ/Blueman reliability settings.

## Effective Outcome

- Legacy Linux desktop paths are removed rather than shimmed: X11/bspwm/sxhkd, Polybar, Dunst, Waybar, old idle services, old browser modules, broad media modules, Spotify/Spicetify, and stale theme/config payloads.
- Zen uses the narrow `github:0xc000022070/zen-browser-flake` input because pinned nixpkgs/unstable lacks a usable Zen package. Current executable/desktop/class defaults are `zen-beta`, `zen-beta.desktop`, and `zen-beta`.
- DMS uses `pkgs.unstable.dms`; Quickshell and Matugen come from unstable.
- Discord uses `pkgs.unstable.vesktop`; the removed `xwaylandvideobridge` alias is not used.
- Darwin remains a shared shell/dev/editor/XDG target; no Linux desktop/system imports were added to Darwin.

## Validation

- `nix flake show --impure --all-systems` passed.
- Retained NixOS host evaluations passed for `ramen`, `harusame`, `udon`, `azar`, `atlas`, and `axiom`.
- `axiom` toplevel dry-run passed locally.
- Key option checks passed for Zen defaults/package/MIME/class, UWSM, DMS service, portals, NetworkManager, Bluetooth, Steam, mpv, and Vesktop config.
- Legacy active-code searches passed for removed desktop/browser/media/Spotify paths.
- Darwin static leakage search passed.
- `git diff --check` passed.

## Residual Risks

- `nix build --impure --dry-run .#nixosConfigurations.ramen.config.system.build.toplevel` is locally blocked by pre-existing agenix host-key assertion for `/etc/ssh/host_ed25519`; `axiom` toplevel dry-run passes.
- Manual runtime checks remain deferred: Hyprland/UWSM startup, DMS UI, portals/screenshare, Wi-Fi roaming, Bluetooth pairing, Steam launch, and mpv playback.
- Darwin build/runtime validation remains deferred to a Darwin machine.
