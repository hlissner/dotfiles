# Axiom Autossh Reverse SSH Tunnel

## Metadata

- `task-id`: `axiom-autossh-reverse-ssh-tunnel`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

`axiom` now has a host-local NixOS systemd service for an autossh reverse SSH tunnel to `root@8.159.128.125`. The service mirrors the existing `charlie` reverse tunnel pattern but uses remote loopback port `2223`, leaving `charlie` on `2222`. The repo change does not alter SSH keys, remote server policy, Cloudflare configuration, or `charlie`.

Validation passed for both the generated service shape and the full `axiom` toplevel build. Live tunnel behavior remains a deployment-time check on physical `axiom` because this environment cannot prove remote auth, host-key trust, or remote port availability.

## Reusable Decisions

- Reverse SSH tunnel remote forwards for these hosts must bind remote loopback explicitly, e.g. `127.0.0.1:<port>:127.0.0.1:22`, rather than exposing on all remote interfaces.
- `charlie` owns remote loopback port `2222`; `axiom` owns remote loopback port `2223`.
- NixOS host variants should run this tunnel as local user `c1` with `HOME=/home/c1` so credentials stay aligned with the user-owned `charlie` launchd model instead of root's local SSH state.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/plan.md`
- `log`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/log.md`
- `tasks`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/tasks.md`
- `rfc`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-change.md`
- `report`: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/report-walkthrough.md`
