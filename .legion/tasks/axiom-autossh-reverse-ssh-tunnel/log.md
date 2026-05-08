# Log: Axiom Autossh Reverse SSH Tunnel

## 2026-05-08

- User requested Legion workflow and an `axiom` SSH tunnel similar to `charlie`.
- Existing `charlie` tunnel pattern uses autossh to forward remote `127.0.0.1:2222` to local `127.0.0.1:22` through `root@8.159.128.125`.
- Clarified that `axiom` should use remote port `2223` to avoid conflict with `charlie`.
- Contract materialized as `axiom-autossh-reverse-ssh-tunnel`.
- RFC design gate passed with a host-local NixOS systemd service approach.
- Implemented `systemd.services.autossh-reverse-ssh` in `hosts/axiom/default.nix`, running as local user `c1` and forwarding remote `127.0.0.1:2223` to local `127.0.0.1:22`.
- Engineer smoke eval confirmed the service ExecStart, service user, multi-user target attachment, and `autossh` package inclusion.
- Verification passed: targeted eval confirmed loopback-only `2223` tunnel shape, service user/environment/restart behavior, and package inclusion.
- Verification passed: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` completed successfully.
- Change review passed with security lens applied; no blocking findings.
- Generated implementation-mode walkthrough and PR body from existing RFC, verification, and review evidence.
- Wiki writeback completed with task summary plus reverse SSH tunnel current-truth decisions.
