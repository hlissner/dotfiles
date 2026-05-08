# Review Change: Wayland Product Overhaul

> Date: 2026-05-08
> Stage: review-change

## Decision

PASS

## Blocking Findings

None remaining.

## Findings Resolved During Review

- Zen integration originally used `zen` and `zen.desktop`, but the selected package exposes `zen-beta`, `zen-beta.desktop`, and `StartupWMClass=zen-beta`. Fixed in `modules/desktop/browsers/zen.nix` and the Hyprland Zen window rule.
- `atlas`, `axiom`, and `azar` still overrode the browser default to `"zen"`. Removed those host-level overrides and verified all six Zen-enabled hosts now evaluate the browser default to `"zen-beta"`.
- User-requested local `axiom` dry-run found build-time issues after the first PASS: NetworkManager dotted INI keys needed quoting, `nm-connection-editor` and `rofi-wayland-unwrapped` were removed package attributes, and Steam `vm.max_map_count` needed `mkForce`. These were fixed and re-reviewed.

## Residual Risks

- `axiom` toplevel dry-run passes locally. `ramen` toplevel dry-run remains blocked by the pre-existing local agenix host-key assertion for `/etc/ssh/host_ed25519`.
- Manual runtime checks remain deferred: Hyprland/UWSM startup, DMS UI, portals/screenshare, Wi-Fi roaming, Bluetooth pairing, Steam launch, and mpv playback.
- Darwin runtime validation remains deferred to a Darwin machine; static Darwin leakage search found no relevant matches.

## Security Lens

Applied because the change touches browser defaults, Discord/Vesktop, NetworkManager/Wi-Fi, Bluetooth, and Steam/firewall-adjacent configuration.

Result: no secrets/tokens and no blocking security findings identified.
