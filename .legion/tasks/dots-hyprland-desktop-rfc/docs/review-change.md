# Change Review: Dots Hyprland Desktop Phase 4

> Conclusion: PASS
> Date: 2026-05-09
> Reviewed evidence: implementation diff, `plan.md`, `docs/rfc.md`, `docs/test-report.md`

## Blocking Findings

None.

## Non-Blocking Findings

- Runtime caveats remain: live Quickshell/Hyprland and hardware-backed controls were not exercised in this environment. They must be tested on Axiom before declaring the full desktop experience complete.
- `cliphist` retention remains privacy-sensitive. Current limits bound shell display/readback, not database pruning; follow-up should define retention and clear UX around end4 `ii` runtime behavior.

## Security Lens

Security review was applied because this change touches clipboard history, keyring/polkit, local user groups, and i2c/DDC permissions.

- No blocking exploit or trust-boundary issue was found.
- Clipboard history is default-on but remains behind `modules.desktop.quickshell.search.clipboard.enable`, uses a clear action through the helper, and records retention caveats in `docs/test-report.md`.
- Polkit enables a graphical agent without bypassing authentication.
- `video`/`input`/`i2c` groups and `i2c-dev` are broad local hardware permissions, but they match the declared Phase 4 control-surface scope.
- `gnome-keyring` no longer enables a competing gcr SSH agent, preserving Axiom's existing `programs.ssh.startAgent` ownership.

## Readiness Summary

The change is within the refreshed Phase 4 substrate scope. It rewrites the RFC/contract around `end4.md`, removes old Axiom guide entry points, stops `autumnal` from writing Hyprland desktop visuals, declares Phase 4 packages/services/permissions, switches clipboard watching to `cliphist store`, and records strong Nix build/eval evidence.

Ready to proceed to walkthrough, wiki writeback, and PR lifecycle.
