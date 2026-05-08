# Axiom Runtime Access And Session Fixes

## Metadata

- `task-id`: `axiom-runtime-access-session-fixes`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes two `axiom` post-deploy runtime regressions. Reverse SSH now has a daemon-backed local target: `axiom` uses persistent `sshd.service` instead of socket-only OpenSSH activation, and `autossh-reverse-ssh` wants/orders after `sshd.service` while preserving remote loopback `127.0.0.1:2223`. Hyprland startup now uses the evaluated `start-hyprland` launcher path through UWSM instead of the `hyprland-uwsm.desktop` path that resolved to direct `Hyprland`.

Local validation passed for generated SSH/tunnel shape, UWSM dry-run command resolution, and the full `axiom` toplevel build. Live remote SSH and physical display login remain deployment checks on real `axiom`.

## Reusable Decisions

- `axiom` reverse SSH should use persistent `sshd.service`; do not rely on OpenSSH socket activation for the autossh local target path.
- `axiom` autossh reverse tunnel remains remote-loopback-only on `127.0.0.1:2223`.
- Active Hyprland greetd/UWSM startup should resolve to `start-hyprland`, not direct `Hyprland` through `hyprland-uwsm.desktop`.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-runtime-access-session-fixes/plan.md`
- `log`: `.legion/tasks/axiom-runtime-access-session-fixes/log.md`
- `tasks`: `.legion/tasks/axiom-runtime-access-session-fixes/tasks.md`
- `rfc`: `.legion/tasks/axiom-runtime-access-session-fixes/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-runtime-access-session-fixes/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-change.md`
- `report`: `.legion/tasks/axiom-runtime-access-session-fixes/docs/report-walkthrough.md`
