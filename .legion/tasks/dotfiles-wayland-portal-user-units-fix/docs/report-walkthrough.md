# Report Walkthrough: Portal User Units Fix

> Mode: implementation

## Summary

The prior Wayland overhaul caused `xdg.portal.extraPortals` to merge into a duplicate list. During actual `axiom` system build, the user systemd unit builder attempted to link `xdg-desktop-portal-gtk.service` twice and failed.

## Change

- `modules/desktop/hyprland.nix` now forces the effective portal package list to exactly `xdg-desktop-portal-hyprland` plus `xdg-desktop-portal-gtk`.
- `config.common.default = [ "hyprland" "gtk" ]` is unchanged.

## Evidence

- Reproduced the duplicate portal package list before the fix.
- Reproduced the reported `axiom` build failure before the fix.
- Verified all Hyprland hosts now evaluate exactly one Hyprland portal and one GTK portal.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes.
- Readiness review PASS in `docs/review-change.md`.
