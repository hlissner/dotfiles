## Summary

- Add an Axiom `SUPER+/` keybinding that opens a graphical shortcut reference modal.
- Generate the modal text and helper script from Nix, using a themed `zenity --text-info --modal` dialog.
- Keep existing shortcut command targets unchanged and scope the feature to Axiom Hyprland integration.

## Validation

- PASS: focused `nix eval` for generated keybind assertions
- PASS: `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
- PASS: realized helper script and shortcut text inspection
- PASS: assembled Hyprland `--verify-config` returned `config ok`
- PASS: `git diff --check`

## Notes

- Live `SUPER+/` smoke still needs deployment in the real Axiom Hyprland session.
- Shortcut help text is repo-generated and should be updated when generated keybinds change.
