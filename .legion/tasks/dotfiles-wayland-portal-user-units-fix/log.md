# Log

## 2026-05-08

- User reported `nixosConfigurations.axiom.config.system.build.toplevel` build failure in `user-units.drv`: duplicate `xdg-desktop-portal-gtk.service` symlink.
- Reproduced with `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Confirmed `axiom.config.xdg.portal.extraPortals` evaluated to duplicate package names: `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`.
- Fixed `modules/desktop/hyprland.nix` to `mkForce` the intended unique portal package list.
- Rebuilt `axiom` toplevel successfully and verified all Hyprland hosts evaluate the same unique portal list.
- Review-change passed with no blocking findings; added walkthrough and PR body.
