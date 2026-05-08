# Review Change: Axiom Runtime Access And Session Fixes

## Verdict
PASS

## Blocking Findings
None.

## Security Lens
Applied. This change affects SSH service availability and a reverse SSH tunnel path.

Security-relevant checks:
- SSH authentication policy remains key-only; no password auth, authorized keys, host keys, user accounts, or remote server config are changed.
- The reverse tunnel command remains remote-loopback-only: `127.0.0.1:2223:127.0.0.1:22`.
- The remote tunnel still runs as local user `c1` and still targets `root@8.159.128.125`.
- Persistent `sshd.service` increases local SSH listener availability, but `axiom` already enabled SSH and allowed TCP/22 before this change.
- `autossh-reverse-ssh` now wants/orders after `sshd.service`, making the local tunnel target explicit and verifiable.

No exploitable trust-boundary expansion was found in the repo change. The remaining risk is deployment-time: confirm the autossh service actually authenticates to `8.159.128.125` and remote loopback port `2223` is listening.

## Correctness Review
PASS. The targeted eval proves `services.openssh.startWhenNeeded = false`, generated `sshd.service` exists, generated `sshd.socket` is absent, and autossh still uses the intended `2223` loopback forward.

PASS. The Hyprland greetd command now uses the evaluated `start-hyprland` path, and UWSM dry-run resolves the command to `start-hyprland` rather than direct `Hyprland`.

## Scope Review
PASS. Production changes are limited to `hosts/axiom/default.nix` and `modules/desktop/hyprland.nix`, matching the two reported runtime symptoms. No Cloudflare, remote host, SSH key, shell, DMS/Quickshell, wallpaper, or lock-screen behavior is changed.

## Verification Review
PASS. `docs/test-report.md` includes targeted eval, UWSM dry-run, and full `axiom` build evidence. Live physical checks are correctly documented as residual deployment validation rather than claimed as complete.

## Non-blocking Notes
- The `mkForce false` override is necessary because the workstation profile also sets `services.openssh.startWhenNeeded = true`.
- The UWSM generated unit identity may change from the previous desktop-entry name to `start-hyprland`; this is acceptable because the existing dotfiles session bootstrap uses `hey hook startup` and `hyprland-session.target`, both preserved by the change.
