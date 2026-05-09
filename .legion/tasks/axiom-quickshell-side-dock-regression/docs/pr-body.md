## Summary

- Fixes the PR #14 regression where the Axiom left side dock disappeared.
- Splits the dock and notification panel into separate `Variants` blocks so each per-screen delegate has one `PanelWindow`.
- Leaves notification center logic, Quickshell service ownership, Hyprland/UWSM/session wiring, and fallback tools unchanged.

## Validation

- `git diff --cached --check`
- `rg -n "Variants \\{|PanelWindow \\{" "config/quickshell/axiom-shell/shell.qml"`
- `nix eval --impure --json --expr '<quickshell service ownership query>'`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes

- Headless/offscreen Quickshell still cannot load `PanelWindow` because this environment has no layer-shell backend.
- Real Axiom Hyprland session should confirm the left dock is visible and the notification panel still toggles.
