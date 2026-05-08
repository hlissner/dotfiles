# RFC: Axiom Runtime Access And Session Fixes

## Status
Draft for `review-rfc`.

## Context
`axiom` now has an autossh reverse SSH tunnel intended to expose local SSH through remote `127.0.0.1:2223` on `root@8.159.128.125`. After deploy, the user reports:

```text
channel 0: open failed: connect failed: Connection refused
stdio forwarding failed
Connection closed by UNKNOWN port 65535
```

The generated `axiom` config currently has `services.openssh.startWhenNeeded = true`, no persistent `sshd.service`, and a generated `sshd.socket` with `ListenStream = [ 22 ]`. The autossh service still forwards to local `127.0.0.1:22` and is ordered after `sshd.service`, but that service does not exist in socket-activation mode.

`axiom` also reports a Hyprland warning that it was started without `start-hyprland`. Current greetd command is:

```text
uwsm start -eD Hyprland hyprland-uwsm.desktop
```

Dry-running that command shows UWSM reparses `hyprland-uwsm.desktop` and resolves the compositor command line to `/run/current-system/sw/bin/Hyprland`, which matches the warning-prone direct compositor launch. The evaluated Hyprland package provides `${config.programs.hyprland.package}/bin/start-hyprland`, and `uwsm start -n -e -D Hyprland <that path>` resolves to that launcher directly.

## Options

### SSH Option A: Keep socket activation and change tunnel target/order
Keep `services.openssh.startWhenNeeded = true`, change autossh to target a socket-activation-friendly endpoint, or order it against `sshd.socket`.

Pros:
- Preserves current workstation socket activation behavior.
- Minimal change to global OpenSSH process lifetime.

Cons:
- Does not address the user-visible refusal if socket activation is not reliably serving the reverse tunnel target.
- `autossh` itself does not need local SSH at startup, so ordering against the socket does not prove the target will accept forwarded connections later.
- Harder to verify than a persistent daemon in this repo-only environment.

### SSH Option B: Make `axiom` OpenSSH persistent and order autossh after it
Set `services.openssh.startWhenNeeded = false` for `axiom`, and make the autossh service want/order after `sshd.service` so local `127.0.0.1:22` is a real daemon-backed target.

Pros:
- Directly addresses the local target availability failure mode.
- Produces an evaluable `sshd.service`, making autossh ordering meaningful.
- Keeps SSH key-only authentication and the existing reverse tunnel port/bind unchanged.

Cons:
- SSH listens persistently after boot instead of on demand.
- Live remote access still needs deployment-time validation.

### Hyprland Option A: Continue using `hyprland-uwsm.desktop`
Keep the current command and treat the warning as benign.

Pros:
- No change to the current display-manager command.

Cons:
- User explicitly reports the warning and wants it fixed.
- UWSM dry-run shows this path resolves to direct `Hyprland`, not `start-hyprland`.

### Hyprland Option B: Point UWSM at the evaluated `start-hyprland` path
Change greetd to run `uwsm start -eD Hyprland ${config.programs.hyprland.package}/bin/start-hyprland`.

Pros:
- Uses the launcher Hyprland now recommends.
- Avoids relying on desktop-entry discovery in greetd's environment.
- Locally verifiable by checking the generated greetd command and UWSM dry-run command shape.

Cons:
- Generated UWSM unit ID changes from `hyprland-uwsm.desktop` to `start-hyprland`.
- Live compositor startup still requires physical `axiom` validation.

## Decision
Use SSH Option B and Hyprland Option B.

Implementation should:

- Override `axiom` OpenSSH to persistent mode by setting `services.openssh.startWhenNeeded = false` in the host config.
- Add `sshd.service` to autossh `wants` and keep it in `after` so the reverse tunnel has a daemon-backed local SSH target.
- Preserve autossh remote forward `127.0.0.1:2223:127.0.0.1:22`, `User = "c1"`, `HOME = "/home/c1"`, `BatchMode=yes`, and loopback-only remote bind.
- Change the Hyprland greetd command to call UWSM with the evaluated `start-hyprland` path instead of `hyprland-uwsm.desktop`.
- Preserve `exec-once = hey hook startup` and the `hyprland-session.target` bootstrap hook.

## Security Boundary
- SSH authentication policy stays key-only; no password auth, authorized keys, host keys, or remote server config are changed.
- Persistent `sshd` increases service availability, but inbound TCP/22 was already allowed and SSH service was already enabled for `axiom`.
- The reverse tunnel remains remote-loopback-only on `127.0.0.1:2223`; do not change this bind address in this task.

## Rollback
Revert the changes to `hosts/axiom/default.nix` and `modules/desktop/hyprland.nix`, rebuild/switch `axiom`, and the system returns to socket-activated OpenSSH plus the previous UWSM desktop-entry command. No data migration or remote cleanup is required.

## Verification
- Targeted eval: confirm `services.openssh.startWhenNeeded = false`, `sshd.service` exists, `sshd.socket` is not active, autossh still forwards `127.0.0.1:2223:127.0.0.1:22`, and autossh wants/orders after `sshd.service`.
- Targeted eval: confirm greetd command contains `/bin/start-hyprland`, does not contain `hyprland-uwsm.desktop`, and startup hooks still start `hyprland-session.target`.
- Full build: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Residual deployment checks: confirm `systemctl status sshd autossh-reverse-ssh`, remote `127.0.0.1:2223` is listening on `8.159.128.125`, and physical login no longer prints the Hyprland warning.
