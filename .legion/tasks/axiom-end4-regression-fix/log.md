# Axiom End4 Regression Fix Log

## 2026-05-09

- User reported PR #19 broke left sidebar / `Super+Space` behavior and Colemak keyboard layout.
- Opened mandatory isolated worktree `.worktrees/axiom-end4-regression-fix/` on branch `legion/axiom-end4-regression-fix-hotkeys-layout` from `origin/master`.
- Materialized a narrow hotfix contract: restore launcher/sidebar keybind and keyboard layout as Axiom-generated Hyprland overrides while keeping end4 `ii` active.
- User clarified the primary goal remains complete end4 import, not a narrow fallback repair. Updated contract: the imported end4 `ii` shell must load successfully; reported hotkey/layout regressions are necessary completion fixes within that larger import goal.
- Live `quickshell.service` logs show repeated failure loading `/home/c1/.config/quickshell/ii/shell.qml`: `module "org.kde.kirigami" is not installed` via `WaffleFamily -> WaffleActionCenter -> FluentIcon`. This explains missing shell surfaces such as sidebar/launcher.
- Patched Quickshell wrapper generation to include `kdePackages.kirigami.unwrapped` in QML import paths and export both `QML2_IMPORT_PATH` and `QML_IMPORT_PATH`.
- Patched generated Hyprland `custom/general.conf` to re-apply host XKB facts after imported upstream defaults; Axiom now evaluates to `kb_layout = us`, `kb_variant = colemak`, and `kb_options = terminate:ctrl_alt_bksp`.
- Patched generated Hyprland `custom/keybinds.conf` to restore `Super+Space` as an end4 search/launcher IPC entrypoint and `Super+A` as a direct left-sidebar IPC entrypoint.
- Recorded `docs/test-report.md`. Quickshell package build, generated config evals, Kirigami QML path check, service ExecStart eval, headless smoke to expected PanelWindow backend limit, and full Axiom toplevel build passed.
- Change review PASS with no blockers. Review confirmed the fix preserves the end4 `ii` import goal, directly addresses the Kirigami QML failure, restores Colemak generated config, and wires `Super+Space`/`Super+A` through end4 IPC.
- Generated reviewer walkthrough and PR body: `docs/report-walkthrough.md`, `docs/pr-body.md`.
- Completed Legion wiki writeback with task summary plus durable end4 decisions/patterns/maintenance notes for QML module path validation, generated Hyprland host override layering, and live hotkey/layout follow-up.
