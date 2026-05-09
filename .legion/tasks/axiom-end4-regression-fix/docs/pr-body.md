## Summary

- Fix the live end4 `ii` startup failure by adding the actual Kirigami QML module path to the wrapped Quickshell runtime.
- Restore Axiom-owned Hyprland input facts so Colemak overrides imported upstream `kb_layout = us` defaults.
- Restore host-level end4 IPC hotkeys for `Super+Space` launcher/search and `Super+A` left sidebar.

## Verification

- PASS: live logs identified the pre-fix `org.kde.kirigami` QML failure in `quickshell.service`.
- PASS: generated `hypr/custom/general.conf` evaluates to `kb_layout = us`, `kb_variant = colemak`, and `kb_options = terminate:ctrl_alt_bksp`.
- PASS: generated `hypr/custom/keybinds.conf` evaluates with `Super+Space` and `Super+A` end4 IPC commands.
- PASS: wrapped Quickshell package build, service `ExecStart` eval, Kirigami QML path check, headless smoke to expected PanelWindow backend limit, and full Axiom toplevel build.

## Risks/Follow-ups

- After deployment, restart/switch the fixed generation and confirm `quickshell.service` no longer logs missing `org.kde.kirigami`.
- Confirm `Super+Space`, `Super+A`, and Colemak behavior in the live Hyprland session.

## Legion Evidence

- Contract: `.legion/tasks/axiom-end4-regression-fix/plan.md`
- Test report: `.legion/tasks/axiom-end4-regression-fix/docs/test-report.md`
- Change review: `.legion/tasks/axiom-end4-regression-fix/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-end4-regression-fix/docs/report-walkthrough.md`
