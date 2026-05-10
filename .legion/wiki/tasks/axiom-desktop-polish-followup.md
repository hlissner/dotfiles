# Axiom Desktop Polish Followup

## Metadata

- `task-id`: `axiom-desktop-polish-followup`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-05-10-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes three Axiom desktop polish regressions after the Caelestia migration. Steam now gets fractional-scale HiDPI handling through generated Hyprland XWayland self-scaling for scaled monitors plus a wrapped Steam desktop UI scale of `1.500000` on Axiom. Caelestia keybinds no longer depend on the reported broken `global, caelestia:*` dispatcher path; generated bindings use reviewed `caelestia shell ...` IPC commands for drawers, brightness, media, and picker actions.

The task also replaces Axiom's ineffective literal `environment.variables.PATH = "$HOME/.opencode/bin:$PATH"` with explicit zsh startup and UWSM/Hyprland session PATH ownership for `$HOME/.opencode/bin`. Local validation passed for generated config shape, Steam wrapper readback, Steam closure presence, assembled Hyprland parser validation, diff hygiene, and the Axiom toplevel build. Live Steam crispness, Caelestia key dispatch, and opencode binary presence remain deployment smoke checks.

## Reusable Decisions

- For Axiom fractional-scale Steam UI regressions, validate compositor XWayland scaling and the actual Steam wrapper before expanding into game/Proton debugging.
- When Caelestia global-shortcut dispatch is broken, reviewed `caelestia shell ...` IPC commands are an acceptable generated-keybind target; do not restore top-level `catchall`.
- Axiom opencode PATH ownership should be explicit in zsh and generated UWSM session PATH, not represented only by a literal global PATH string.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-desktop-polish-followup/plan.md`
- `log`: `.legion/tasks/axiom-desktop-polish-followup/log.md`
- `tasks`: `.legion/tasks/axiom-desktop-polish-followup/tasks.md`
- `rfc`: `.legion/tasks/axiom-desktop-polish-followup/docs/rfc.md`
- `review-rfc`: `.legion/tasks/axiom-desktop-polish-followup/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-desktop-polish-followup/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-desktop-polish-followup/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-desktop-polish-followup/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-desktop-polish-followup/docs/pr-body.md`

## Notes

- Post-deploy smoke should confirm Steam crispness, Caelestia keybind behavior, and `command -v opencode` in both fresh shell and desktop-launched terminal contexts.
