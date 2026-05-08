# Review RFC: Axiom Runtime Access And Session Fixes

## Verdict
PASS

## Findings
No blocking design issues found.

## Rationale
- The RFC directly addresses both reported symptoms with minimal, bounded changes.
- The SSH decision is implementable and verifiable: persistent `sshd.service` gives the reverse tunnel a daemon-backed local target, and generated systemd units can prove the shape.
- The Hyprland decision is implementable and evidence-driven: dry-run evidence shows the current desktop-entry path resolves to direct `Hyprland`, while the evaluated package exposes `start-hyprland`.
- Rollback is simple: revert the host-local SSH changes and the shared Hyprland greetd command change.
- Verification is specific enough to catch regressions in the remote-forward shape, SSH activation mode, and Hyprland startup command.

## Security Notes
- This design keeps SSH key-only policy unchanged and does not expand the reverse tunnel bind address beyond remote loopback.
- Persistent `sshd` is an intentional availability trade-off for the reverse tunnel and is acceptable because `axiom` already enables SSH and opens TCP/22.
- Live remote auth and port listening remain deployment checks, not repo-level blockers.

## Suggestions
- In implementation, keep the autossh command itself unchanged unless targeted eval or build proves a direct mismatch.
- Verification should explicitly assert `sshd.service` exists and `sshd.socket` is absent/inactive after disabling `startWhenNeeded`.
