# Review RFC: Axiom Autossh Reverse SSH Tunnel

## Verdict
PASS

## Findings
No blocking design issues found.

## Rationale
- Scope is narrow and host-local: production changes are limited to `hosts/axiom/default.nix` plus task evidence.
- The RFC captures the meaningful alternatives: host-local systemd service, reusable module, and Cloudflare replacement.
- The selected design is implementable on NixOS and preserves the `charlie` tunnel semantics while adapting the service manager.
- Verification is credible for this environment: generated service evaluation plus full `axiom` build can prove repo integration.
- Rollback is simple: revert the host-local service/package change and rebuild/deploy `axiom`.

## Security Review Notes
- The RFC correctly treats this as a remote-access surface change.
- The remote bind address must remain `127.0.0.1`, not an empty bind address or `0.0.0.0`.
- The remote port must remain `2223` to avoid conflict with `charlie` on `2222`.
- Live authentication, host-key trust, and remote port availability remain deployment risks, not repo-level design blockers.

## Suggestions
- In implementation, prefer running the systemd service as local user `c1` with `HOME=/home/c1` so it mirrors the `charlie` user-agent credential model rather than using root's local SSH state.
- Verification should include a targeted eval of the service user, environment, and ExecStart string in addition to the full `axiom` build.
