# Log: Axiom Runtime Access And Session Fixes

## 2026-05-08

- User reported that after switching/rebuilding `axiom`, reverse SSH access fails with `channel 0: open failed: connect failed: Connection refused`, followed by `stdio forwarding failed` and `Connection closed by UNKNOWN port 65535`.
- User also reported a boot/login warning: Hyprland was started without `start-hyprland`, which upstream says is not recommended outside debugging.
- Initial diagnosis: the reverse tunnel likely reaches `axiom`, but local `127.0.0.1:22` is refusing connections because `axiom` uses OpenSSH socket activation; Hyprland startup likely still uses a command shape that calls the compositor directly through UWSM instead of the recommended launcher.
- Contract materialized as `axiom-runtime-access-session-fixes`.
- Targeted eval confirmed current `axiom` has `services.openssh.startWhenNeeded = true`, no generated `sshd.service`, generated `sshd.socket`, and autossh still ordered after nonexistent `sshd.service`.
- Targeted/dry-run evidence confirmed current greetd command uses `uwsm start -eD Hyprland hyprland-uwsm.desktop`, and UWSM resolves that path to direct `/run/current-system/sw/bin/Hyprland` rather than `start-hyprland`.
- RFC review passed: use persistent `sshd.service` for `axiom` and point greetd/UWSM at the evaluated `start-hyprland` path.
- Implemented `axiom` OpenSSH override with `mkForce false` for `services.openssh.startWhenNeeded` because the workstation profile also sets it to true.
- Updated `autossh-reverse-ssh` to want `sshd.service` in addition to ordering after it, while preserving the existing remote loopback forward.
- Updated Hyprland greetd/UWSM command to use the evaluated `${config.programs.hyprland.package}/bin/start-hyprland` path.
- Engineer smoke eval passed: persistent `sshd.service` exists, `sshd.socket` is absent, autossh wants/orders after `sshd.service`, and greetd uses `start-hyprland` without `hyprland-uwsm.desktop`.
- Verification passed: targeted eval confirmed SSH activation mode, autossh dependencies/forward shape, and Hyprland startup command.
- Verification passed: UWSM dry run resolves the new command to `start-hyprland`.
- Verification passed: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` completed successfully.
- Change review passed with security lens applied; no blocking findings.
- Generated implementation-mode walkthrough and PR body from existing RFC, verification, and review evidence.
- Wiki writeback completed with task summary plus current decisions/patterns for persistent `sshd.service`, `start-hyprland`, UWSM dry-run validation, and autossh local-target checks.
