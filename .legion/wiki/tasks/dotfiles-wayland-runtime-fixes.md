# Dotfiles Wayland Runtime Fixes

Status: PR-ready implementation handoff
Task: `.legion/tasks/dotfiles-wayland-runtime-fixes/`
Branch: `legion/dotfiles-wayland-runtime-fixes`

## Summary

Fixed two `axiom` runtime regressions after the Wayland product overhaul: greetd/UWSM referenced a missing Hyprland desktop entry, and network startup had conflicting ownership between NetworkManager/iwd and legacy DHCP paths.

## Effective Outcome

- greetd now starts UWSM with `hyprland-uwsm.desktop`, which is the actual evaluated Hyprland session entry.
- The missing `hyprland.desktop` entry is no longer referenced.
- iwd remains the NetworkManager Wi-Fi backend, but iwd's built-in network configuration is disabled so NetworkManager owns DHCP/routes.
- `axiom` disables legacy `dhcpcd` and gets an `enp14s0` NetworkManager wired DHCP/autoconnect ensure profile.
- `axiom` toplevel build passes locally with `nix build --impure --no-link`.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- Targeted eval confirmed `hyprland-uwsm.desktop` exists, `hyprland.desktop` does not, and greetd references `hyprland-uwsm.desktop`.
- Targeted eval confirmed NetworkManager+iwd+resolved ownership and disabled/absent `dhcpcd`.
- `git diff --check` passed.

## Residual Risk

Physical runtime checks still need to happen on `axiom`; local validation proves the generated closure and effective Nix configuration.
