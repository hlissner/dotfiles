## Summary

- Implements RFC Stage 1 by adding a session-local Quickshell notification center next to the Axiom side dock.
- Preserves Quickshell service ownership under `hyprland-session.target` and keeps Hyprland/UWSM/session modules unchanged.
- Adds Legion evidence for the approved dots-hyprland RFC, this implementation contract, verification, review, and walkthrough.

## Validation

- `git diff --cached --check`
- `nix eval --impure --json --expr '<quickshell service ownership query>'`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- `rg -n "PersistentProperties|FileView|clipboard|search|DesktopEntries|dynamic|matugen|rofi|DMS" "config/quickshell/axiom-shell" --glob "*.qml"`

## Notes

- Headless Quickshell smoke reaches config loading but stops at `No PanelWindow backend loaded`; real notification action/dismiss/clear behavior still needs Axiom Hyprland session testing.
- No notification persistence, clipboard history, shell search/actions, quick controls, OSD, dynamic theming, or upstream installer import is included.
