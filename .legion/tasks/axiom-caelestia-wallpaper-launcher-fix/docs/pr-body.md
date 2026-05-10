## Summary

- Make Caelestia the wallpaper owner for Axiom and stop Hyprland from also starting `swaybg` in that mode.
- Seed Caelestia's wallpaper state on service start when missing, using `/home/c1/the-great-sage.jpg` from host wallpaper policy.
- Fix Caelestia launcher/runtime execution by expanding the service PATH, adding `--no-duplicate`, and moving restart/lock paths away from unmanaged shell/logind-crash behavior.

## Validation

- `nix eval --impure --json --expr '<targeted generated config checks>'`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure`

## Notes

- Live post-deploy check should confirm one quickshell instance, one Caelestia background layer, no `swaybg`, and launcher Enter starts Zen.
