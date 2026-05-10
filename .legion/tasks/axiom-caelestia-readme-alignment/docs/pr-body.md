## Summary

- Align Axiom Caelestia settings with README-style fonts, Thunar explorer defaults, qtengine, and rounded Hyprland decoration.
- Add the locked `kossLAN/qtengine` flake input and wire the qtengine module/env for Caelestia, Hyprland, UWSM, and the user session.
- Install and declare the requested font packages/fallbacks, including Chinese sans/mono fallbacks and FiraCode Nerd Font Mono for Foot.

## Verification

- `nix eval` checks for generated Caelestia shell JSON, Foot config, fontconfig fallbacks, Qt env, Thunar/GVFS, and qtengine enablement.
- Generated Hyprland config verified with configured Hyprland 0.53.3: `config ok`.
- `nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`

## Notes

- Live visual confirmation still requires deploying Axiom and restarting Hyprland/apps.
