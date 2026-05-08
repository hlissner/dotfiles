# Report Walkthrough: Axiom Autossh Reverse SSH Tunnel

Mode: implementation

## Summary
- Adds a boot-started NixOS systemd service on `axiom` for an autossh reverse SSH tunnel to `root@8.159.128.125`.
- Mirrors `charlie`'s tunnel behavior while using remote loopback port `2223` instead of `2222`.
- Keeps the change host-local and avoids modifying `charlie`, Cloudflare, SSH keys, or remote server configuration.

## What Changed
- `hosts/axiom/default.nix`: adds `autossh` to `user.packages`.
- `hosts/axiom/default.nix`: adds `systemd.services.autossh-reverse-ssh` with `wantedBy = [ "multi-user.target" ]`.
- The service runs as local user `c1`, sets `HOME=/home/c1`, and runs autossh with `-M 0`, SSH keepalives, `ExitOnForwardFailure=yes`, `BatchMode=yes`, and `-R 127.0.0.1:2223:127.0.0.1:22`.

## Design Notes
- RFC decision: host-local systemd service was chosen over a reusable module because this is a one-host addition and touching `charlie` would increase blast radius.
- `BatchMode=yes` is specific to the systemd version so auth/host-key problems fail and restart rather than trying interactive prompts.
- Remote bind remains `127.0.0.1`, so this client command does not expose the forwarded port on all remote interfaces.

## Verification
- PASS: targeted `nix eval` confirmed the service user, working directory, restart behavior, autossh package inclusion, remote target, loopback-only bind, and `2223` remote forward.
- PASS: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` completed successfully and generated `unit-autossh-reverse-ssh.service.drv`.

## Review
- RFC review: PASS.
- Change review: PASS with security lens applied.
- No blocking findings.

## Residual Risk
- Live tunnel behavior was not validated from this environment.
- After deployment, verify that physical `axiom` has usable SSH credentials for `root@8.159.128.125`, remote host-key trust is in place, and remote `127.0.0.1:2223` is free.

## Evidence
- Contract: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/plan.md`
- RFC: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/rfc.md`
- RFC review: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-rfc.md`
- Verification: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/test-report.md`
- Change review: `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-change.md`
