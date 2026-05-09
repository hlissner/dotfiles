## Summary

- Reopen the end4 desktop RFC as an implementation task and align the phase/theme direction with `end4.md`.
- Add Phase 4 declarative substrate for Quickshell/end4 services: runtime packages, `cliphist`, keyring, polkit, power profiles, i2c/DDC, user groups, and fallback controls.
- Remove old Axiom guide entry points and stop `autumnal` from writing Hyprland desktop visuals.

## Validation

- `nix eval --impure --json --expr ...` for Phase 4 service/package/user-group wiring
- `python3 -c 'import ast, pathlib; ...'` for changed helper syntax
- active source grep for old guide references
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Notes

- This is a Phase 4 substrate PR, not the full end4 `ii/shell.qml` import; `origin/master` still lacks prior Phase 1-3 end4 sources.
- Live Quickshell/Hyprland and hardware-backed control checks must run on Axiom after deployment.
- `cliphist` retention pruning is not implemented here; the watcher can be disabled and cleared, and retention policy remains follow-up work.
