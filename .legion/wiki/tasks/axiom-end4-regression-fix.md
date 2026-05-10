# Axiom End4 Regression Fix

## Metadata

- `task-id`: `axiom-end4-regression-fix`
- `status`: `historical`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-caelestia-shell-migration`

## Outcome Summary

This hotfix is historical. It kept the complete end4 `ii` import active at the time and fixed the first live regressions found after PR #19. Live `quickshell.service` logs showed imported `ii` failed before shell surfaces appeared because `org.kde.kirigami` was missing from the wrapped runtime QML paths. The patch added the actual Kirigami QML module path, restored Axiom's Colemak XKB facts after upstream Hyprland defaults, and reintroduced host hotkeys for end4 search and left-sidebar IPC.

Repository-local validation passed, including generated config evals, wrapped Quickshell package build, Kirigami path check, service `ExecStart` eval, bounded headless smoke to the expected `PanelWindow` backend limit, full Axiom toplevel build, and readiness review. Live graphical confirmation remains a post-deployment step because this task did not switch the PR worktree generation into the active session.

## Reusable Decisions

- Missing QML modules in imported end4 `ii` are integration blockers, not optional polish or reasons to fall back to legacy `axiom-shell`.
- KDE/QML wrapper packages must be checked for actual module trees; end4 imports may need unwrapped QML derivations in `QML2_IMPORT_PATH` and `QML_IMPORT_PATH`.
- Axiom host facts such as XKB layout/variant/options and primary desktop hotkeys belong in Nix-generated Hyprland custom files layered after imported upstream defaults.
- Historical only: `Super+Space` and `Super+A` routed to end4 IPC before `axiom-caelestia-shell-migration`; current active shell bindings should target Caelestia.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-end4-regression-fix/plan.md`
- `log`: `.legion/tasks/axiom-end4-regression-fix/log.md`
- `tasks`: `.legion/tasks/axiom-end4-regression-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-end4-regression-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-end4-regression-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-end4-regression-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-end4-regression-fix/docs/pr-body.md`

## Notes

- Post-deployment validation should restart or reload the fixed `quickshell.service`, confirm the Kirigami failure is absent from logs, and test `Super+Space`, `Super+A`, and Colemak inside the live Hyprland session.
