## Summary

- Add a reusable Fcitx5 input module with GTK/Qt frontends, Rime, Chinese addons, and Catppuccin theme support.
- Enable the reusable Fcitx5 setup on `axiom` with Catppuccin Mocha and set the wallpaper to `/home/c1/the-great-sage.jpg` stretched across the screen.
- Keep existing `fcitx5-rime.enable` host configs working through delegation.
- Scope Quickshell startup to `hyprland-session.target` and replace stale `swaybg` instances on wallpaper reload.

## Validation

- Evaluated `axiom` Fcitx5 enable/type/addons/theme/wallpaper via git-flake source.
- Evaluated existing `atlas` `fcitx5-rime` compatibility.
- Evaluated `quickshell.service` target wiring and generated wallpaper hook shape.
- Evaluated `.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` successfully.

## Notes

- This does not package official WeType for Linux; no stable Linux package URL or nixpkgs package was found.
