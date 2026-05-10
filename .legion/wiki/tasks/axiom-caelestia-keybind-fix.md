# Axiom Caelestia Keybind Fix

## Metadata

- `task-id`: `axiom-caelestia-keybind-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This hotfix fixes two Caelestia migration runtime regressions on Axiom. Generated Hyprland keybinds no longer include the invalid top-level `catchall` binding that caused `Invalid catchall, catchall keybinds are only allowed in submaps`, while the normal Caelestia launcher and explicit mouse interrupt bindings remain.

The local Caelestia integration also exposes standard icon theme and MIME fallback packages in the Axiom user package closure: `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils`. This targets checkerboard placeholder icons without changing the selected GTK icon theme or importing end4 fallback behavior.

Validation passed for generated keybind text, evaluated user package closure, assembled Hyprland parser config, diff hygiene, and Axiom system toplevel build. Live Caelestia icon rendering and launcher interruption behavior still need confirmation in the actual Hyprland session.

## Reusable Decisions

- Do not use top-level Hyprland `catchall` binds for Caelestia launcher interruption; Hyprland only permits `catchall` inside submaps.
- Keep Caelestia icon/MIME fallback packages in the local Caelestia integration boundary, not in unrelated theme code.
- Run assembled `Hyprland --verify-config` for generated keybind/rule changes because Nix eval/build does not parse Hyprland syntax.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-keybind-fix/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-keybind-fix/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-keybind-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-caelestia-keybind-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-keybind-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-keybind-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-keybind-fix/docs/pr-body.md`

## Notes

- Post-deployment validation should rebuild/switch Axiom, confirm Hyprland no longer reports the `catchall` config error, and verify Caelestia icons no longer render as checkerboard placeholders.
