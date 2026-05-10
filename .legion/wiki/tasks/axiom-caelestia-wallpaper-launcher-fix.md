# Axiom Caelestia Wallpaper And Launcher Fix

## Metadata

- `task-id`: `axiom-caelestia-wallpaper-launcher-fix`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task addresses live Axiom regressions after the Caelestia Shell migration. The desired wallpaper owner is Caelestia, so the implementation makes Axiom opt into Caelestia wallpaper ownership, gates off the old Hyprland `swaybg` startup hook in that mode, and seeds Caelestia's mutable wallpaper state from `/home/c1/the-great-sage.jpg` only when the state file is missing or empty.

The task also fixes launcher/runtime process boundaries by giving `caelestia-shell.service` an explicit PATH, adding quickshell `--no-duplicate`, and routing shell restart/stop keybinds through `systemctl --user`. Ordinary idle/keybind lock paths now use `hyprlock` directly while Caelestia's logind lock handling is crashing in the live session.

Validation passed for targeted generated config checks and the Axiom NixOS toplevel build. Live Wayland validation remains required after deployment because static checks cannot prove layer-shell rendering, duplicate instance cleanup, or launcher focus/Enter behavior.

## Reusable Decisions

- Caelestia is Axiom's wallpaper owner when `modules.desktop.caelestia.wallpaper.enable = true`; do not run `swaybg` in that mode.
- Seed Caelestia wallpaper state as mutable runtime state, not as an immutable home-manager file.
- Keep Caelestia shell lifecycle under `caelestia-shell.service`; use `--no-duplicate` and systemd restart/stop paths.
- Give Caelestia's service PATH enough application/runtime packages for launcher and helper subprocess execution.
- Use direct `hyprlock` for ordinary lock paths until Caelestia logind lock handling is fixed and verified.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-wallpaper-launcher-fix/docs/pr-body.md`

## Notes

- Post-deploy cleanup should remove the currently unmanaged duplicate quickshell instance before validating final layer state.
- If `/home/c1/the-great-sage.jpg` still fails Caelestia image decode live, keep Caelestia ownership and create a follow-up for a display-sized asset or upstream image handling fix.
