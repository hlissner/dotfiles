# Dotfiles Wayland Runtime Follow-up

Status: PR-ready implementation handoff
Task: `.legion/tasks/dotfiles-wayland-runtime-followup/`
Branch: `legion/dotfiles-wayland-runtime-followup`

## Summary

Fixed follow-up `axiom` runtime regressions where Hyprland 0.53 rejected old `windowrulev2`/layer-rule syntax and NetworkManager still had default connection creation disabled.

## Effective Outcome

- Active generated and checked-in Hyprland window rules now use Hyprland 0.53 `windowrule = match:..., effect ...` syntax.
- Active layer rules now use current `layerrule = match:namespace ..., effect ...` syntax.
- Removed obsolete `gestures.workspace_swipe`, which failed current Hyprland parser validation and was only disabling already-disabled behavior.
- NetworkManager no longer sets `no-auto-default=*`, allowing fallback default connection creation when profiles are missing or stale.
- Network ownership remains NetworkManager + iwd + resolved; iwd does not own DHCP/routes and `dhcpcd` remains disabled/absent.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- `Hyprland --verify-config` passed against combined generated/base/theme config for Hyprland 0.53.3.
- Targeted eval confirmed `windowrulev2` is absent, current `windowrule` syntax is generated, NetworkManager `no-auto-default` is absent, and NetworkManager/iwd/resolved ownership remains coherent.
- `git diff --check` passed.

## Residual Risk

Physical login and network behavior still need to be checked on `axiom`; local validation proves generated config, parser compatibility, and NixOS build behavior.
