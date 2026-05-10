# Axiom SSH Autossh and Opencode Cloudflared Fix

## Metadata

- `task-id`: `axiom-ssh-opencode-cloudflared-fix`
- `status`: `active`
- `risk`: `high`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes the XDG SSH wrapper path bug that made OpenSSH look for a literal `$XDG_CONFIG_HOME/ssh/config`, adds a daemon-backed `azar` autossh reverse SSH tunnel on remote loopback port `2224`, and adds `axiom` `opencode-server` plus a new `home-axiom` Cloudflare tunnel for `opencode-axiom.0xc1.space`.

Local validation passed for targeted generated config/service shape and both affected NixOS toplevel builds. Cloudflare tunnel creation and the corrected DNS route also succeeded. A post-deploy follow-up found Linux cloudflared config could not be linked by Home Manager under the root-owned agenix credential directory; the module now generates Linux connector config at `/etc/cloudflared/config.yml` while Darwin keeps home-managed config. Runtime switch/restart still requires root authorization on `axiom`.

## Reusable Decisions

- `azar` owns remote reverse SSH loopback port `2224` for `root@8.159.128.125`, forwarding to local `127.0.0.1:22` through a NixOS systemd `autossh-reverse-ssh` service.
- NixOS hosts using a reverse tunnel to local SSH should use persistent `sshd.service` rather than socket-only OpenSSH activation.
- `axiom` opencode exposure uses local-only `opencode serve --hostname 127.0.0.1 --port 4096` plus cloudflared ingress; Cloudflare Access remains required before treating the hostname as safe for use.
- The active axiom opencode hostname is `opencode-axiom.0xc1.space`; `axiom-opencode.0xc1.space` was a mistaken route and should not be used.
- Linux cloudflared age secrets should use group `users`; Darwin keeps `staff`.
- Linux cloudflared connector config should be system-owned under `/etc/cloudflared/config.yml`, not home-managed under `~/.cloudflared`, because agenix may own the credential directory before Home Manager activation.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/plan.md`
- `log`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/log.md`
- `tasks`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/tasks.md`
- `research`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/research.md`
- `rfc`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/test-report.md`
- `change-review`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/review-change.md`
- `report`: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/report-walkthrough.md`
