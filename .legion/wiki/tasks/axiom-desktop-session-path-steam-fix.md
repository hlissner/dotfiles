# axiom-desktop-session-path-steam-fix

## Metadata

- `task-id`: `axiom-desktop-session-path-steam-fix`
- `status`: `completed`
- `risk`: `medium`
- `schema-version`: `2026-05-10`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes the `axiom` graphical session command environment so desktop-launched Foot and GUI apps receive a usable PATH. Hyprland/UWSM now exports a deterministic session PATH and imports it into the systemd user manager before starting `hyprland-session.target`. Caelestia Shell keeps explicit service PATH ownership, but now includes generated system packages as well as helpers and user packages so launcher children can resolve `git`, `gawk`, `steam`, and `steam-run`.

Steam runtime internals were not changed. If Steam still fails after the PATH fix is deployed, capture logs and split that into a separate Steam runtime task.

## Reusable Decisions

- Axiom Hyprland/UWSM sessions should export a deterministic PATH from generated `uwsm/env` and import `PATH` into systemd user startup.
- Caelestia Shell's explicit service path should include Caelestia helpers, user packages, and generated system packages because it is a launcher/app2unit parent.
- For GUI app launch failures that differ between SSH and the desktop session, validate generated session PATH and service path ownership before patching individual app commands.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-desktop-session-path-steam-fix/plan.md`
- `log`: `.legion/tasks/axiom-desktop-session-path-steam-fix/log.md`
- `tasks`: `.legion/tasks/axiom-desktop-session-path-steam-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-desktop-session-path-steam-fix/docs/rfc.md`
- `review-rfc`: `.legion/tasks/axiom-desktop-session-path-steam-fix/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-desktop-session-path-steam-fix/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-desktop-session-path-steam-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-desktop-session-path-steam-fix/docs/report-walkthrough.md`
