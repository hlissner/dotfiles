## Summary

- Fix duplicate portal package registration that caused `user-units.drv` to fail while linking `xdg-desktop-portal-gtk.service`.
- Force the intended unique Hyprland portal package list: Hyprland portal plus GTK fallback.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- `nix eval --impure --json .#nixosConfigurations.{ramen,harusame,udon,azar,atlas,axiom}.config.xdg.portal.extraPortals --apply 'builtins.map (p: p.name)'`
- `git diff --check`

## Evidence Docs

- `.legion/tasks/dotfiles-wayland-portal-user-units-fix/docs/test-report.md`
- `.legion/tasks/dotfiles-wayland-portal-user-units-fix/docs/review-change.md`
- `.legion/tasks/dotfiles-wayland-portal-user-units-fix/docs/report-walkthrough.md`
