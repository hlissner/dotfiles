# Report Walkthrough: Axiom Runtime Access And Session Fixes

Mode: implementation

## Summary
- Fixes `axiom` reverse SSH local target availability by switching OpenSSH from socket activation to persistent `sshd.service`.
- Keeps autossh's remote loopback forward unchanged: `127.0.0.1:2223:127.0.0.1:22` to `root@8.159.128.125`.
- Fixes the Hyprland startup warning by changing greetd/UWSM from `hyprland-uwsm.desktop` to the evaluated `start-hyprland` launcher path.

## What Changed
- `hosts/axiom/default.nix`: overrides `services.openssh.startWhenNeeded` to `mkForce false` so `axiom` generates a persistent `sshd.service`.
- `hosts/axiom/default.nix`: adds `sshd.service` to `autossh-reverse-ssh.wants`, while preserving autossh user, remote target, and remote forward.
- `modules/desktop/hyprland.nix`: changes greetd's default session command to `uwsm start -eD Hyprland ${config.programs.hyprland.package}/bin/start-hyprland`.

## Why
- The reported SSH error shows the reverse access path reaches a refused connection; a daemon-backed local SSH target removes dependence on socket-only activation for forwarded local `127.0.0.1:22`.
- UWSM dry-run showed the previous `hyprland-uwsm.desktop` command resolves to direct `Hyprland`, matching the reported upstream warning. The new command resolves to `start-hyprland`.

## Verification
- PASS: targeted eval confirmed persistent `sshd.service`, no `sshd.socket`, autossh wanted/after `sshd.service`, unchanged `2223` reverse-forward shape, and preserved session bootstrap hook.
- PASS: UWSM dry-run confirmed the new command line is the evaluated `start-hyprland` path.
- PASS: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` completed successfully.

## Review
- RFC review: PASS.
- Change review: PASS with security lens applied.
- No blocking findings.

## Deployment Checks
- Run `systemctl status sshd autossh-reverse-ssh` on physical `axiom` after switch.
- On `8.159.128.125`, confirm remote `127.0.0.1:2223` is listening.
- Log in graphically on `axiom` and confirm the Hyprland `start-hyprland` warning is gone.

## Evidence
- Contract: `.legion/tasks/axiom-runtime-access-session-fixes/plan.md`
- RFC: `.legion/tasks/axiom-runtime-access-session-fixes/docs/rfc.md`
- RFC review: `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-rfc.md`
- Verification: `.legion/tasks/axiom-runtime-access-session-fixes/docs/test-report.md`
- Change review: `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-change.md`
