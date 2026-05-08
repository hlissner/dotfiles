# Review Change

## Result

PASS

## Blocking Findings

None.

## Scope Review

The change stays within the approved follow-up scope:

- `modules/desktop/hyprland.nix` converts generated product window/layer rules to Hyprland 0.53 syntax.
- `config/hypr/hyprland.conf` converts checked-in base window/layer rules and removes the obsolete `gestures.workspace_swipe` setting that failed parser validation.
- `modules/themes/autumnal/hyprland.nix` converts theme layer rules to Hyprland 0.53 syntax.
- `modules/profiles/hardware/wifi.nix` removes `no-auto-default=*` so NetworkManager can create fallback default connections.
- Legion evidence was added under `.legion/tasks/dotfiles-wayland-runtime-followup/`.

No browser, Steam feature, Discord feature, Bluetooth, broad desktop redesign, old X11 compatibility, secrets, or Darwin behavior changes were introduced.

## Correctness Review

- Hyprland 0.53.3 source confirms `windowrulev2` is registered as a parse error, while `windowrule` v3 accepts `match:<prop> <value>, <effect> <value>` fields.
- Converted rules use current effect/property names such as `match:class`, `match:title`, `match:namespace`, `suppress_event`, `idle_inhibit`, `no_anim`, `no_blur`, `no_shadow`, `no_max_size`, `min_size`, and `border_size`.
- `Hyprland --verify-config` passes against the combined generated/base/theme config, which directly covers the reported syntax errors.
- Removing `networkmanager.settings.main."no-auto-default" = "*"` is the smallest network startup fix for remaining no-network symptoms because it lets NetworkManager create default connection profiles when declarative or persisted profiles are absent/stale.
- Existing ownership remains coherent: NetworkManager is enabled, uses iwd and systemd-resolved, iwd does not own DHCP/routes, and `dhcpcd` remains disabled/absent.

## Security Lens

Applied because the change touches session config parsing and privileged network service defaults.

No security blocker found:

- No credentials, secrets, or new privileged scripts were added.
- NetworkManager remains the single network owner; no legacy DHCP daemon is reintroduced.
- Allowing NetworkManager default profiles may auto-create wired/Wi-Fi connection entries, but this is standard NetworkManager behavior and does not add network secrets or bypass authentication.
- Hyprland rule changes only update parser syntax/effect names; they do not broaden command execution paths.

## Non-blocking Notes

- Physical `axiom` login and network tests still need to happen after deployment. Local validation proves generated config, parser compatibility, and NixOS build behavior.
