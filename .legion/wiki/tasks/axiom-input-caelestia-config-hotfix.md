# Axiom Input And Caelestia Config Hotfix

## Metadata

- `task-id`: `axiom-input-caelestia-config-hotfix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This hotfix addresses two Axiom Caelestia/Hyprland runtime pain points. Generated Hyprland keybinds now use canonical uppercase modifier tokens such as `SUPER`, `CTRL`, `ALT`, and `SHIFT`, while retaining the existing Caelestia CLI IPC commands and host keybind actions.

Caelestia `shell.json` is no longer emitted as a Home Manager Nix-store file. The Caelestia user service now seeds a normal writable `~/.config/caelestia/shell.json` before startup when the file is missing or when an old symlink points into `/nix/store`; existing real files and non-Nix user symlinks are preserved.

The default seed also disables Caelestia keyboard layout change toasts via `utilities.toasts.kbLayoutChanged = false`, preventing the reported boot-time `Unknown` layout notification from repo-owned defaults. Static validation passed; live Super-key and boot-toast behavior still requires post-deploy Hyprland session smoke.

## Reusable Decisions

- Axiom Caelestia `shell.json` is now a mutable user config seeded from repository defaults, not a continuously Home Manager-owned immutable file.
- Generated Hyprland keybinds should use canonical uppercase modifier names, especially for `SUPER`, and generated keybind/rule changes still require assembled Hyprland parser validation.
- Repository defaults may suppress noisy Caelestia keyboard layout toasts, but unknown live `active_keymap` reports should be investigated separately if they persist in `hyprctl -j devices`.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-input-caelestia-config-hotfix/plan.md`
- `log`: `.legion/tasks/axiom-input-caelestia-config-hotfix/log.md`
- `tasks`: `.legion/tasks/axiom-input-caelestia-config-hotfix/tasks.md`
- `test-report`: `.legion/tasks/axiom-input-caelestia-config-hotfix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-input-caelestia-config-hotfix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-input-caelestia-config-hotfix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-input-caelestia-config-hotfix/docs/pr-body.md`

## Notes

- Post-deploy validation should switch Axiom, restart `caelestia-shell.service`, confirm `~/.config/caelestia/shell.json` is a writable regular file, exercise `SUPER+Space`, `SUPER+Return`, and workspace bindings, and confirm the boot-time keyboard layout `Unknown` toast no longer appears by default.
