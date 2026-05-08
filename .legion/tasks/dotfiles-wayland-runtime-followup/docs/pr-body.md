## Summary

- Convert active Hyprland window/layer rules from removed `windowrulev2`/old layer syntax to Hyprland 0.53 `windowrule`/`layerrule` syntax.
- Remove obsolete `gestures.workspace_swipe`, which fails current Hyprland config parsing.
- Remove NetworkManager `no-auto-default=*` so `axiom` can create fallback default connections when profiles are missing or stale.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- `Hyprland --verify-config` against combined generated/base/theme config
- Targeted eval for Hyprland syntax and NetworkManager/iwd/resolved/dhcpcd state
- `git diff --check`

## Notes

- Runtime login and physical network checks still need to be done on `axiom`; this PR validates the generated closure, Hyprland parser compatibility, and effective configuration.
