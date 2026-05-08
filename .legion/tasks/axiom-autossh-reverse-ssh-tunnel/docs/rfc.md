# RFC: Axiom Autossh Reverse SSH Tunnel

## Status
Draft for `review-rfc`.

## Context
`charlie` already runs a launchd user agent named `autossh-reverse-ssh` that executes autossh with `-M 0`, SSH keepalive options, `ExitOnForwardFailure=yes`, and `-R 127.0.0.1:2222:127.0.0.1:22 root@8.159.128.125`. `axiom` is a NixOS host, so the same operational pattern should be expressed as a systemd service rather than copied as launchd configuration.

The user confirmed that `axiom` should use remote port `2223`, avoiding conflict with `charlie` on `2222`.

## Options

### Option A: Host-local systemd service on `axiom`
Add `systemd.services.autossh-reverse-ssh` in `hosts/axiom/default.nix`. Run autossh as user `c1` from a boot-started system service, set `HOME=/home/c1`, and forward `127.0.0.1:2223` on the remote host to local `127.0.0.1:22`.

Pros:
- Smallest production change and contained to the affected host.
- Keeps SSH credentials owned by the same local user model as `charlie`.
- Starts without requiring a graphical login session.
- Easy to verify through the evaluated systemd unit and full `axiom` build.

Cons:
- Duplicates the tunnel pattern instead of creating a reusable module.
- Live authentication and remote port availability still require deployment-time validation.

### Option B: New reusable autossh reverse tunnel module
Create a shared module for reverse SSH tunnels and enable it from both `charlie` and `axiom`.

Pros:
- Removes duplication if more hosts need the same pattern.
- Centralizes future defaults and flags.

Cons:
- Larger blast radius because it touches existing `charlie` behavior.
- Cross-platform module design would need launchd/systemd abstraction for only one new consumer.
- More verification required for no current operational gain.

### Option C: Replace this with Cloudflare Access/WARP routing
Do not add autossh; instead extend Cloudflare access paths.

Pros:
- Aligns with existing Cloudflare Zero Trust documentation.
- Avoids another direct SSH tunnel to the external host.

Cons:
- Not the requested access pattern.
- Requires Cloudflare app/tunnel/policy work outside the current scope.
- Does not match `charlie`'s existing emergency reverse tunnel behavior.

## Decision
Use Option A.

The implementation should stay in `hosts/axiom/default.nix` and add a boot-started systemd service:

- `after = [ "network-online.target" "sshd.service" ]`
- `wants = [ "network-online.target" ]`
- `wantedBy = [ "multi-user.target" ]`
- run as local user `c1`
- set `AUTOSSH_GATETIME=0` and `HOME=/home/c1`
- execute autossh with `-M 0 -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -R 127.0.0.1:2223:127.0.0.1:22 root@8.159.128.125`
- restart automatically, matching the persistent behavior of `charlie`'s launchd `KeepAlive = true`

`BatchMode=yes` is intentionally added for the systemd variant so the service fails and restarts instead of attempting interactive authentication or host-key prompts in a non-interactive context.

## Security Boundary
- The remote bind address remains `127.0.0.1`, so the forwarded port is not directly exposed on all remote interfaces by this client command.
- This does not change SSH authentication policy, keys, or remote server authorization.
- The change still increases operational access to `axiom` from the remote host itself, so review must check that the bind address is loopback-only and the port is unique.

## Rollback
Revert the `hosts/axiom/default.nix` service/package change and rebuild/deploy `axiom`. No data migration, state migration, or remote cleanup is required from the repo side. If a live tunnel had been started, stopping the systemd service or deploying the reverted generation terminates it.

## Verification
- Evaluate the generated `axiom` service to confirm ExecStart contains the expected autossh command, `127.0.0.1:2223:127.0.0.1:22`, `root@8.159.128.125`, and the intended service user/environment.
- Build `axiom` with `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Record that live SSH authentication and remote port binding cannot be proven from this environment without deploying to physical `axiom` and reaching `8.159.128.125`.
