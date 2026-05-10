## Summary

- Fixes the Axiom Hyprland parse error caused by a top-level `catchall` keybind generated during the Caelestia migration.
- Removes `bindin = Super, catchall, global, caelestia:launcherInterrupt` while keeping Caelestia launcher and explicit mouse interrupt bindings.
- Adds the standard icon theme/MIME runtime packages (`hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, `xdg-utils`) to the local Caelestia integration for checkerboard placeholder icons.
- Keeps the fix scoped to generated Hyprland syntax; no end4 fallback or broader keybind redesign is introduced.

## Validation

- PASS: generated `hypr/custom/keybinds.conf` eval no longer contains `catchall`
- PASS: source regression search found no `catchall` in `modules/desktop/*.nix`
- PASS: Axiom evaluated user packages include Caelestia shell/CLI plus icon theme and MIME fallback packages
- PASS: assembled Axiom Hyprland config returns `config ok` with `Hyprland --verify-config`
- PASS: `git diff --check`
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Review Notes

- Mode: implementation
- Test evidence: `.legion/tasks/axiom-caelestia-keybind-fix/docs/test-report.md`
- Readiness review: `.legion/tasks/axiom-caelestia-keybind-fix/docs/review-change.md` records PASS with no blocking findings.

## Follow-ups

- Optional live-session confirmation that Caelestia launcher interruption behavior still feels correct after the parser-safe binding removal and that icons no longer render as checkerboard placeholders.
