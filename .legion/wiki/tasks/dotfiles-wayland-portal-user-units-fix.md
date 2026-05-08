# Dotfiles Wayland Portal User Units Fix

Status: PR-ready implementation handoff
Task: `.legion/tasks/dotfiles-wayland-portal-user-units-fix/`
Branch: `legion/dotfiles-wayland-portal-user-units-fix`

## Summary

Fixed a build-stage regression where duplicate `xdg.portal.extraPortals` entries caused `user-units.drv` to fail linking `xdg-desktop-portal-gtk.service`.

## Effective Outcome

- Hyprland portal configuration now forces the effective portal package list to exactly Hyprland portal plus GTK fallback.
- `axiom` toplevel build passes locally with `nix build --impure --no-link`.
- All six Hyprland hosts evaluate the same unique portal package list.

## Residual Risk

Future host-specific extra portal additions must update or intentionally override the central forced portal list.
