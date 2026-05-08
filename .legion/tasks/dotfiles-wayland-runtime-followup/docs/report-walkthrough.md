# Report Walkthrough

Mode: implementation

## Reviewer Summary

- Converts active Hyprland window/layer rules from removed/deprecated syntax to Hyprland 0.53 `windowrule`/`layerrule` syntax.
- Removes obsolete `gestures.workspace_swipe` after Hyprland parser validation showed it no longer exists.
- Removes NetworkManager `no-auto-default=*` so `axiom` can fall back to NetworkManager-created default connections when declarative/persisted profiles are missing or stale.

## Files To Review

- `modules/desktop/hyprland.nix`: generated product rules now use `windowrule = match:..., effect ...` and current layer rule effect names.
- `config/hypr/hyprland.conf`: checked-in base Hyprland rules and layer rules now use current syntax; removed obsolete `gestures.workspace_swipe`.
- `modules/themes/autumnal/hyprland.nix`: theme layer rules now use current `layerrule` syntax.
- `modules/profiles/hardware/wifi.nix`: NetworkManager default connection creation is no longer disabled.
- `.legion/tasks/dotfiles-wayland-runtime-followup/docs/test-report.md`: build/parser/eval evidence.
- `.legion/tasks/dotfiles-wayland-runtime-followup/docs/review-change.md`: readiness review result.

## Validation Evidence

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- `Hyprland --verify-config` passed against the combined generated/base/theme config for Hyprland 0.53.3.
- Targeted eval confirms `windowrulev2` is absent and generated config uses current `windowrule` syntax.
- Targeted eval confirms NetworkManager+iwd+resolved remain enabled, iwd DHCP/routes remain disabled, `dhcpcd` remains absent, and NetworkManager `no-auto-default` is absent.
- `git diff --check` passed.

## Review Result

`docs/review-change.md` is PASS with no blocking findings. Security lens was applied for session config parsing and network service defaults; no security blocker was found.

## Residual Risk

Physical login and network behavior still need to be checked on `axiom` after deployment. Local validation proves generated config, Hyprland parser compatibility, and NixOS build behavior.
