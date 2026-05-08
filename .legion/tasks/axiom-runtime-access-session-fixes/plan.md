# Axiom Runtime Access And Session Fixes

## Task ID
`axiom-runtime-access-session-fixes`

## Goal
Fix two post-deploy `axiom` runtime regressions: the autossh reverse SSH tunnel reaches `axiom` but fails with local `Connection refused`, and Hyprland warns that it was started without `start-hyprland`.

## Problem
After rebuilding and switching the latest `axiom` configuration, connecting through the new reverse tunnel fails with:

```text
channel 0: open failed: connect failed: Connection refused
stdio forwarding failed
Connection closed by UNKNOWN port 65535
```

That error means the remote reverse tunnel accepted the inbound connection but the `axiom` side could not connect to its local SSH target. The current `axiom` config enables `services.openssh.startWhenNeeded`, so the tunnel may be forwarding to `127.0.0.1:22` while no persistent `sshd` listener is available for that loopback target.

Separately, the graphical login path starts Hyprland through UWSM but still triggers the upstream warning that Hyprland was started without `start-hyprland`. The startup command should use the evaluated, recommended Hyprland/UWSM launcher rather than continuing to call a path that upstream treats as a debugging-only launch mode.

## Acceptance
- `axiom` exposes a reliable local SSH listener for the autossh reverse tunnel target after boot.
- The autossh reverse tunnel still forwards remote `127.0.0.1:2223` to local `127.0.0.1:22` and still runs as local user `c1`.
- The generated `axiom` SSH service shape no longer depends on socket-only OpenSSH activation for the reverse tunnel path.
- The generated greetd/UWSM command starts Hyprland through the evaluated recommended launcher and no longer matches the warning-prone direct `Hyprland` command shape.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes.
- Targeted evals prove the SSH/tunnel and Hyprland session command shape.

## Scope
- Update `axiom` host/service settings needed to make local SSH reachable for the reverse tunnel.
- Update the shared Hyprland/UWSM greetd startup command only as needed to remove the `start-hyprland` warning while preserving the existing `hyprland-session.target` bootstrap.
- Add Legion RFC, review, verification, walkthrough, and wiki evidence.

## Non-goals
- Do not change remote host `8.159.128.125` or its SSH server policy.
- Do not change SSH keys, authorized keys, password auth policy, or Cloudflare configuration.
- Do not redesign the Wayland desktop stack, DMS/Quickshell, wallpaper startup hooks, or lock-screen policy.
- Do not validate live physical display rendering or live remote SSH connectivity from this environment; record those as deployment checks.

## Assumptions
- The reported SSH error is from connecting through remote port `2223` after the autossh service came up.
- `axiom` should keep the existing reverse tunnel port ownership: remote `127.0.0.1:2223` belongs to `axiom`.
- A persistent OpenSSH daemon on `axiom` is acceptable for this workstation because inbound port `22` is already allowed and SSH service is enabled.
- The evaluated Hyprland/UWSM package provides a launcher path that can be verified locally, even though live compositor startup must be checked on physical `axiom`.

## Constraints
- Follow Legion workflow and the git-worktree PR envelope.
- Keep changes minimal and directly tied to the two reported symptoms.
- Preserve the existing `charlie` tunnel and existing reverse tunnel loopback bind decision.

## Risks
- Local build/eval can prove generated config, not live remote SSH authentication or physical display behavior.
- Changing OpenSSH from socket activation to a persistent daemon affects when SSH is listening on `axiom`, though key-only auth policy remains unchanged.
- Hyprland/UWSM startup command details depend on the evaluated package version and must be validated against generated session data.

## Design Summary
Treat the SSH failure as a local target availability issue: keep autossh's remote forward unchanged, but make `axiom` run a persistent OpenSSH daemon instead of relying on `startWhenNeeded` socket activation for the reverse tunnel's loopback target. Treat the Hyprland warning as a startup command mismatch: preserve UWSM/greetd and the session bootstrap hooks, but switch the command to the evaluated launcher shape that uses `start-hyprland` rather than calling `Hyprland` directly.

## Phases
1. Materialize this task contract.
2. Write and review a short RFC because this touches remote access and display-manager startup behavior.
3. Implement minimal SSH and Hyprland/UWSM startup fixes.
4. Verify with targeted evals plus full `axiom` toplevel build.
5. Run change review, walkthrough, wiki writeback, and PR lifecycle.
