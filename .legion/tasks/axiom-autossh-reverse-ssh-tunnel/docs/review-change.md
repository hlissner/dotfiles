# Review Change: Axiom Autossh Reverse SSH Tunnel

## Verdict
PASS

## Blocking Findings
None.

## Security Lens
Applied. This change modifies a remote access path by creating a reverse SSH tunnel from `axiom` to `root@8.159.128.125`.

Security-relevant checks:
- Remote bind is explicitly loopback-only: `127.0.0.1:2223`.
- Remote port `2223` is distinct from `charlie`'s `2222`.
- Local forwarded target is `127.0.0.1:22`, matching the requested SSH access pattern.
- No SSH keys, secrets, remote authorization policy, Cloudflare policy, or password authentication settings are changed.
- The service runs as local user `c1` instead of root, matching the credential ownership model of `charlie`'s user launchd agent.

No exploitable trust-boundary issue was found in the repo change. The remaining security/operational risk is deployment-time: physical `axiom` must have the intended SSH credentials and host-key trust, and remote `127.0.0.1:2223` must be free.

## Scope Review
PASS. Production configuration changes are limited to `hosts/axiom/default.nix`; `charlie`, Cloudflare, SSH server policy, and remote host configuration are untouched.

## Verification Review
PASS. `docs/test-report.md` includes both targeted service eval and full `axiom` toplevel build evidence. The targeted eval directly checks the security-sensitive tunnel shape and service properties.

## Non-blocking Notes
- `Restart = "always"` is acceptable because it mirrors launchd `KeepAlive = true`; `RestartSec = "10s"` limits tight restart loops.
- Live tunnel behavior cannot be proven until deployment, which is correctly documented as a residual risk rather than claimed as verified.
