## Summary

- Canonicalize Axiom Hyprland generated keybind modifiers to `SUPER`/`CTRL`/`ALT`/`SHIFT`.
- Seed Caelestia `shell.json` as a writable user file instead of a Home Manager Nix-store symlink.
- Disable Caelestia keyboard layout change toasts in the default seed to avoid boot-time `Unknown` layout notifications.

## Validation

- PASS: focused `nix eval` generated-config assertions
- PASS: inspected realized Caelestia shell seed script and seed JSON
- PASS: assembled Hyprland `--verify-config` returned `config ok`
- PASS: `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
- PASS: `git diff --check`

## Notes

- Existing real `~/.config/caelestia/shell.json` files and non-Nix user symlinks are preserved.
- Live Super-key and boot-toast smoke still needs to be done in the deployed Axiom Hyprland session.
