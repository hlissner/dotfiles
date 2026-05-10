# Review RFC: axiom-caelestia-shell-migration

Date: 2026-05-10

## Decision

PASS.

The RFC is implementable, verifiable, and rollbackable before engineering begins. It defines a clear architecture boundary: consume Caelestia's upstream CLI-enabled Nix package, keep local NixOS ownership of service/XDG/Hyprland integration, remove active end4 product sources, and validate with Nix evaluation/build plus targeted active-reference scans.

## Blocking Findings

None.

## Non-Blocking Suggestions

- During implementation, first prove the upstream package output path (`packages.${system}.with-cli`) with a focused eval before large source deletion, so package-output drift is caught early.
- Make the active-reference scan explicitly exclude historical `.legion/tasks/**` evidence and distinguish wiki current-truth files from archived task records.
- When wiring keybinds, record which Caelestia shortcuts are static/global-dispatch only versus CLI-backed, because live Wayland validation may be unavailable in automation.

## Review Notes

- Rollback is adequate: PR revert for merge-time rollback and previous NixOS generation for runtime rollback, without preserving end4 as product truth.
- Verification is adequate for a headless implementation environment: service command/package path, generated config files, active end4 reference absence, Axiom toplevel build, diff hygiene, and optional live smoke tests are specified.
- Scope is bounded: the design does not require porting end4 features, importing the full Caelestia dots repository, or broadening Home Manager ownership.
