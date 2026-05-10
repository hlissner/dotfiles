# RFC: Axiom SSH Autossh and Opencode Cloudflared Fix

> **Profile**: RFC Heavy  
> **Status**: Draft  
> **Owners**: agent / c1  
> **Created**: 2026-05-10  
> **Last Updated**: 2026-05-10

## Executive Summary

- **Problem**: SSH XDG config is found by the filesystem but passed to OpenSSH as a literal `$XDG_CONFIG_HOME/ssh/config` path; `azar` lacks a declarative reverse SSH tunnel; `axiom` lacks a systemd-managed opencode server and axiom-specific cloudflared ingress.
- **Decision**: Fix runtime expansion in the XDG SSH wrappers, add an `azar` systemd autossh service on remote loopback port `2224`, and add `axiom` `opencode-server` plus `modules.services.cloudflared` ingress for `opencode-axiom.0xc1.space`.
- **Why now**: The user is actively blocked on SSH to `azar` and wants axiom opencode reachable through Cloudflare.
- **Impact**: NixOS host configs for `axiom` and `azar` change; `charlie` remains untouched.
- **Risks**: Cloudflare tunnel creation and Access policy are external; autossh runtime can still fail on remote auth, host key trust, or occupied remote ports.
- **Rollout**: Commit declarative config, generate encrypted axiom cloudflared credentials, then deploy to `axiom` and `azar` separately.
- **Rollback**: Revert the host config changes and stop/remove the new Cloudflare tunnel or hostname route if created.

## 1. Background / Motivation

`modules.xdg.ssh.enable` wraps OpenSSH so Linux hosts can use XDG SSH config and keys. The current wrapper computes `dir='$XDG_CONFIG_HOME/ssh'`, which preserves the dollar expression literally. When `$HOME/.config/ssh/config` exists, the wrapper chooses `-F "$XDG_CONFIG_HOME/ssh/config"`; OpenSSH then reports that the user config file cannot be opened even though `/home/c1/.config/ssh/config` exists.

`charlie` already has a user-owned launchd autossh tunnel to `root@8.159.128.125` on remote loopback port `2222`. `axiom` has the NixOS equivalent on port `2223` and uses persistent `sshd.service`. `azar` has OpenSSH enabled but still uses socket activation and lacks the reverse tunnel service.

`charlie` also has the current opencode/cloudflared pattern: opencode listens on `127.0.0.1:4096`, cloudflared maps a public hostname to that loopback service, and Cloudflare Access remains a required external policy layer. `axiom` should get the Linux systemd equivalent under a new tunnel/hostname, not by changing `charlie`.

## 2. Goals

- Make the XDG SSH wrapper pass an expanded config path to OpenSSH.
- Give `azar` a daemon-backed local SSH target and autossh reverse tunnel on remote loopback `127.0.0.1:2224`.
- Give `axiom` a systemd `opencode-server` service bound to `127.0.0.1:4096`.
- Create and wire an axiom-specific Cloudflare tunnel with encrypted credentials and ingress for `opencode-axiom.0xc1.space`.
- Produce local validation evidence and clearly separate deploy-time/external checks.

## 3. Non-goals

- Do not modify `charlie` autossh, opencode, or cloudflared behavior.
- Do not expose opencode directly on LAN or public interfaces.
- Do not commit plaintext Cloudflare credentials.
- Do not configure Cloudflare Access policy from this repo unless a future task adds a declarative Access management path.
- Do not deploy to physical hosts in this task without separate confirmation.

## 4. Constraints

- Compatibility: preserve existing XDG SSH extra config and key lookup behavior.
- Security: opencode must remain loopback-only; Cloudflare credentials must be age-encrypted.
- Operational: autossh should use `ExitOnForwardFailure=yes` so port conflicts fail loudly.
- Dependency: cloudflared tunnel creation requires external Cloudflare account login and may require manual browser authentication.

## 5. Proposed Design

### 5.1 XDG SSH Wrapper

Replace literal `dir='$XDG_CONFIG_HOME/ssh'` style assignments with runtime-expanded directory resolution:

```sh
dir="${XDG_CONFIG_HOME:-$HOME/.config}/ssh"
cfg="$dir/config"
```

Use the same runtime-expanded `dir` for `ssh`, `scp`, `ssh-add`, and `ssh-copy-id`. Keep the existing behavior that only passes `-F` when the config file exists and is non-empty.

### 5.2 Azar Autossh

Add `autossh` to `hosts/azar/default.nix` packages. Force persistent OpenSSH by setting `services.openssh.startWhenNeeded = mkForce false`, matching `axiom`'s previous runtime fix.

Add `systemd.services.autossh-reverse-ssh` with:

- `after` and `wants`: `network-online.target`, `sshd.service`
- `User`: `c1`
- `HOME`: `/home/c1`
- `AUTOSSH_GATETIME`: `0`
- `ExecStart`: autossh `-M 0 -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -R 127.0.0.1:2224:127.0.0.1:22 root@8.159.128.125`
- restart: always, 10 seconds

### 5.3 Axiom Opencode Systemd

Add `systemd.services.opencode-server` to `hosts/axiom/default.nix`:

- `after`: `network.target`
- `wantedBy`: `multi-user.target`
- `User`: `c1`
- `WorkingDirectory`: `/home/c1`
- `ExecStart`: `/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`
- environment: `HOME=/home/c1`, `OPENCODE_ENABLE_EXA=1`, `OPENCODE_EXPERIMENTAL=true`
- restart: on failure, 10 seconds

Use the absolute opencode path because opencode is installed under the user's managed `.opencode/bin` path rather than as a Nix package in this repo.

### 5.4 Axiom Cloudflared

Use the existing `modules.services.cloudflared` module in `hosts/axiom/default.nix`:

- `enable = true`
- `tunnelId = <new axiom tunnel id>`
- `credentialsFile = ./secrets/cloudflared-credentials.age`
- `warpRouting.enabled = false`
- `extraConfig.tunnelName = "home-axiom"`
- `extraConfig.ingress = [{ hostname = "opencode-axiom.0xc1.space"; service = "http://127.0.0.1:4096"; } { service = "http_status:404"; }]`

Generate `hosts/axiom/secrets/cloudflared-credentials.age` from the tunnel JSON, never committing plaintext credentials.

Create or update the public hostname route with Cloudflare CLI when account state permits:

```sh
cloudflared tunnel route dns home-axiom opencode-axiom.0xc1.space
```

If the CLI cannot complete this because login/account state is unavailable in automation, record it as a deployment blocker rather than claiming hostname exposure is complete.

### 5.5 Cloudflared Linux Secret Group

The shared cloudflared module currently assigns the age secret group to `staff`, which matches the Darwin-oriented charlie setup but is not the Linux service group. Because this task enables the module on NixOS `axiom`, update the module to choose a platform group:

- Darwin: `staff`
- Linux: `users`

Keep the Linux systemd service `Group = "users"` unchanged. This is a directly related module fix required for the axiom cloudflared credential path.

## 6. Alternatives Considered

### Option A: Minimal host-local implementation

- Pros: Smallest change, mirrors current `charlie` and `axiom` patterns, easy to inspect and roll back.
- Cons: Duplicates autossh service shape between `axiom` and `azar`.
- Why choose: Only two NixOS hosts currently need this shape, and the task is a runtime repair rather than a module refactor.

### Option B: Introduce reusable autossh/opencode modules

- Pros: Removes duplication and centralizes port/target config.
- Cons: Larger scope, more option design, more cross-host regression risk.
- Why not: The request is urgent and bounded; reusable abstraction can wait until the pattern appears again or needs stronger policy.

### Option C: Use Cloudflare only for SSH instead of autossh

- Pros: One remote access plane.
- Cons: Changes the existing reverse SSH operational model and does not fix the user-reported autossh requirement.
- Why not: Explicitly out of scope; current decisions reserve autossh remote loopback ports.

### Decision

Choose Option A. It fixes the concrete breakages with the smallest host-local change set while preserving existing operational patterns.

## 7. Rollout / Rollback

### Rollout Plan

1. Land the dotfiles change through the PR branch.
2. Deploy `azar` to pick up the SSH wrapper and autossh service.
3. Deploy `axiom` to pick up the opencode service and cloudflared tunnel connector.
4. Route `opencode-axiom.0xc1.space` to the `home-axiom` tunnel with `cloudflared tunnel route dns home-axiom opencode-axiom.0xc1.space` or record the external blocker.
5. In Cloudflare Zero Trust, ensure `opencode-axiom.0xc1.space` has an Access application and allow policy before treating it as online.
6. Runtime smoke after deploy: `systemctl status sshd autossh-reverse-ssh` on `azar`; `systemctl status opencode-server cloudflared` on `axiom`; browser access through the Access-protected hostname.

### Rollback Plan

- Revert this PR or remove the new service blocks from `hosts/azar/default.nix` and `hosts/axiom/default.nix`.
- Stop disabled runtime services with `systemctl disable --now autossh-reverse-ssh` on `azar` and `systemctl disable --now opencode-server cloudflared` on `axiom` if already deployed.
- Remove or disable the `home-axiom` Cloudflare tunnel and `opencode-axiom.0xc1.space` hostname route if created and no longer needed.
- Restore `azar` OpenSSH socket activation only if no reverse tunnel needs a daemon-backed local target.

## 8. Observability

- `ssh -G azar` after deployment should not report a literal `$XDG_CONFIG_HOME/ssh/config` path failure.
- `journalctl -u autossh-reverse-ssh` on `azar` should show connection/forward failures if remote auth or port ownership is wrong.
- `journalctl -u opencode-server` on `axiom` should show local service startup and failures.
- `journalctl -u cloudflared` on `axiom` should show tunnel registration and ingress errors.

## 9. Security & Privacy

- The opencode HTTP server binds only to `127.0.0.1`.
- The public hostname must be protected by Cloudflare Access before use.
- The cloudflared credential JSON is encrypted into `hosts/axiom/secrets/cloudflared-credentials.age`; plaintext credential files stay out of git.
- Autossh remote forwards bind `127.0.0.1` on the remote host and do not expose SSH on all remote interfaces.

## 10. Testing Strategy

- Targeted eval the SSH wrapper package or generated wrapper text to confirm expanded XDG path logic.
- Targeted eval `azar` systemd units to confirm persistent `sshd.service`, no `sshd.socket`, autossh dependencies, user, and remote forward string.
- Targeted eval `axiom` opencode service and cloudflared config ingress shape.
- Targeted eval cloudflared age secret ownership to confirm Linux uses group `users` while preserving Darwin `staff` behavior.
- Build or drv-evaluate `axiom` and `azar` toplevels if feasible.
- Manual/external validation remains required for Cloudflare login, Access policy, remote autossh auth, and live browser access; DNS route creation should be attempted with Cloudflare CLI and recorded as pass/blocker.

## 11. Milestones

- Milestone 1: Design and task evidence
  - Scope: research and RFC.
  - Acceptance: review-rfc passes or actionable blockers are documented.
  - Rollback impact: docs only.
- Milestone 2: Declarative implementation
  - Scope: `modules/xdg.nix`, `hosts/azar/default.nix`, `hosts/axiom/default.nix`, axiom age secret.
  - Acceptance: local eval/build checks pass or blockers are recorded.
  - Rollback impact: revert PR diff and remove created Cloudflare tunnel if needed.
- Milestone 3: Delivery lifecycle
  - Scope: verification, review, walkthrough, wiki, PR.
  - Acceptance: PR lifecycle reaches merged or a blocked handoff records exact external blockers.
  - Rollback impact: no additional runtime impact beyond Milestone 2.

## 12. Open Questions

- [ ] Can the automation session complete Cloudflare browser login, tunnel creation, and DNS route creation, or must it hand off the exact commands to the user?
- [ ] Is remote port `2224` free on `8.159.128.125`?
- [ ] Is Cloudflare Access for `opencode-axiom.0xc1.space` already present, or must the user create it after the tunnel route exists?

## 13. References

- Plan: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/plan.md`
- Research: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/research.md`
- Relevant files: `modules/xdg.nix`, `hosts/azar/default.nix`, `hosts/axiom/default.nix`, `hosts/charlie/default.nix`, `modules/services/cloudflared.nix`
- Historical wiki: `.legion/wiki/tasks/axiom-autossh-reverse-ssh-tunnel.md`, `.legion/wiki/decisions.md`
