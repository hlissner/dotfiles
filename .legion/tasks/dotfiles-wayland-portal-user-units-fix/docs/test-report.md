# Test Report: Portal User Units Fix

## Commands Run

- `nix eval --impure --json .#nixosConfigurations.axiom.config.xdg.portal.extraPortals --apply 'builtins.map (p: p.name)'` before the fix — reproduced duplicate portal packages: `hyprland`, `gtk`, `hyprland`, `gtk`.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` before the fix — reproduced the reported build failure: duplicate `xdg-desktop-portal-gtk.service` symlink in `user-units.drv`.
- `nix eval --impure --json .#nixosConfigurations.{ramen,harusame,udon,azar,atlas,axiom}.config.xdg.portal.extraPortals --apply 'builtins.map (p: p.name)'` after the fix — passed; each Hyprland host evaluates to exactly `xdg-desktop-portal-hyprland-1.3.11` and `xdg-desktop-portal-gtk-1.15.3`.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` after the fix — passed.
- `git diff --check` — passed.

## Notes

- This is an actual build-stage issue; `nix build --dry-run` did not catch it because the failure occurs inside the `user-units.drv` builder.
