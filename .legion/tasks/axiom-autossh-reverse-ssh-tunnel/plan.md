# Axiom Autossh Reverse SSH Tunnel

## Task ID
`axiom-autossh-reverse-ssh-tunnel`

## Goal
Add an autossh reverse SSH tunnel for the `axiom` NixOS host that mirrors the existing `charlie` tunnel pattern while using a distinct remote port.

## Problem
`charlie` already keeps a reverse SSH tunnel to `root@8.159.128.125`, exposing its local SSH daemon through `127.0.0.1:2222` on the remote host. `axiom` needs the same operational access pattern, but it cannot reuse port `2222` while `charlie` remains active.

## Acceptance
- `axiom` starts an autossh-managed reverse tunnel at boot through a NixOS/systemd service.
- The tunnel forwards remote `127.0.0.1:2223` to `axiom` local `127.0.0.1:22`.
- The tunnel target remains `root@8.159.128.125`, matching `charlie`.
- The service uses autossh health behavior equivalent to `charlie`: monitor port disabled, server alive checks, exit on forward failure, and restart on failure.
- `autossh` is available in the `axiom` system closure.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes, or any blocker is documented with evidence.

## Scope
- Update `hosts/axiom/default.nix` only for the host-local service/package wiring unless verification requires a narrow directly related fix.
- Add or update Legion task artifacts for contract, verification, review, walkthrough, and wiki writeback.
- Preserve the existing `charlie` tunnel and all Cloudflare tunnel configuration.

## Non-goals
- Do not change the remote SSH server configuration on `8.159.128.125`.
- Do not rotate or create SSH keys.
- Do not replace the autossh reverse tunnel with Cloudflare Access, WARP routing, or another access mechanism.
- Do not deploy the configuration to physical `axiom` from this environment.

## Assumptions
- `axiom` already runs OpenSSH locally through `modules.services.ssh.enable = true` and listens on port `22`.
- The remote host accepts `root@8.159.128.125` SSH connections from `axiom` using existing machine/user SSH credentials.
- Remote port `2223` is available and reserved for `axiom`.
- NixOS/systemd is the correct service manager for `axiom`; launchd-specific `charlie` wiring is not reused directly.

## Constraints
- Follow the Legion workflow.
- Use the `git-worktree-pr` envelope before modifying production configuration.
- Keep this change minimal and host-local.
- Do not disturb unrelated dirty work in the main checkout.

## Risks
- The build can prove service generation, but not live remote authentication or remote port availability.
- Missing SSH keys or host key trust on the physical machine could prevent the tunnel from starting after deployment.
- If the remote host already uses port `2223`, autossh will fail because `ExitOnForwardFailure=yes` is intentional.

## Design Summary
Implement a host-local NixOS systemd service on `axiom` that runs `${pkgs.autossh}/bin/autossh` with the same forwarding intent as `charlie`, adjusted from launchd to systemd and from remote port `2222` to `2223`. The service should be ordered after network availability, restart on failure, set `AUTOSSH_GATETIME=0`, disable autossh's monitor port with `-M 0`, and keep SSH's own keepalive/failure behavior. This keeps the operational model familiar while avoiding a shared module until another host needs the pattern.

## Phases
1. Materialize this Legion task contract and checklist.
2. Implement the `axiom` systemd autossh reverse tunnel service.
3. Verify the generated `axiom` system build and targeted service shape.
4. Review the change for scope, safety, and operational risks.
5. Produce walkthrough/PR artifacts and update the Legion wiki.
