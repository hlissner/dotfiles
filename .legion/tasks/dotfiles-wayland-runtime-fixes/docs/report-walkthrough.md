# Report Walkthrough

Mode: implementation

## Reviewer Summary

- Fixes the `axiom` Hyprland login regression by changing greetd/UWSM from nonexistent `hyprland.desktop` to the evaluated `hyprland-uwsm.desktop` session entry.
- Restores coherent `axiom` network ownership by disabling iwd's built-in DHCP/route management, disabling legacy `dhcpcd`, and adding a NetworkManager wired DHCP/autoconnect profile for `enp14s0`.
- Keeps the Wayland-first product direction unchanged: Hyprland + UWSM + NetworkManager + iwd + resolved.

## Files To Review

- `modules/desktop/hyprland.nix`: greetd session command now references `hyprland-uwsm.desktop` and uses `config.programs.uwsm.package`.
- `modules/profiles/hardware/wifi.nix`: iwd no longer owns network configuration when NetworkManager uses iwd as its Wi-Fi backend.
- `hosts/axiom/default.nix`: `enp14s0` wired DHCP/autoconnect moves from legacy interface DHCP/dhcpcd to NetworkManager ensure profiles.
- `.legion/tasks/dotfiles-wayland-runtime-fixes/docs/test-report.md`: build and targeted evaluation evidence.
- `.legion/tasks/dotfiles-wayland-runtime-fixes/docs/review-change.md`: readiness review result.

## Validation Evidence

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- Targeted eval confirms `hyprland-uwsm.desktop` exists, `hyprland.desktop` does not, and greetd references `hyprland-uwsm.desktop`.
- Targeted eval confirms NetworkManager is enabled with `wifi.backend = "iwd"` and `dns = "systemd-resolved"`, iwd `EnableNetworkConfiguration = false`, resolved is enabled, and `dhcpcd` is disabled with no systemd service.
- `git diff --check` passed.

## Review Result

`docs/review-change.md` is PASS with no blocking findings. Security lens was applied for login/session and network service changes; no security blocker was found.

## Residual Risk

Physical runtime checks still need to happen on `axiom`. The local evidence proves the generated closure and effective Nix configuration, not live display-manager startup or link association on the hardware.
