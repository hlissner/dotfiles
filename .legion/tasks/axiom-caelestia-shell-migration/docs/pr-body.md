## Summary

- Migrates Axiom's active desktop shell from the vendored end4 `ii`/legacy Quickshell path to Caelestia Shell via the upstream Nix `with-cli` package.
- Keeps repository-owned integration boundaries for the systemd user service, generated Caelestia XDG config, Hyprland session startup, host facts, and rollback through Nix generations.
- Removes active end4 runtime/config source trees and updates desktop documentation to reflect Caelestia as the current shell direction.

## Validation

- PASS: `nix eval --raw github:caelestia-dots/shell#packages.x86_64-linux.with-cli.name`
- PASS: evaluated Axiom `caelestia-shell.service` ExecStart points at `/nix/store/...-caelestia-shell-1.0.0/bin/caelestia-shell`
- PASS: evaluated generated `~/.config/caelestia/shell.json` with minimal Nix-owned defaults and `launcher.enableDangerousActions = false`
- PASS: evaluated generated Hyprland keybinds using Caelestia global shortcuts and CLI-backed commands
- PASS: active source scan over `config`, `modules`, and `README.md` found no targeted legacy end4/`ii` runtime references
- PASS: `git diff --check`
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`
- SKIP: live graphical smoke, because the validation shell had no Wayland/Hyprland session variables

## Review Notes

- Mode: implementation
- Design evidence: `.legion/tasks/axiom-caelestia-shell-migration/docs/rfc.md`
- Test evidence: `.legion/tasks/axiom-caelestia-shell-migration/docs/test-report.md`
- Readiness review: `.legion/tasks/axiom-caelestia-shell-migration/docs/review-change.md` records PASS with no blocking findings.

## Follow-ups

- Post-deployment live Hyprland smoke for panel rendering, global shortcuts, launcher/sidebar/session UI, screenshot/record/clipboard flows, tray, and OSD behavior.
- Optional live or assembled-config `Hyprland --verify-config`.
- Completed Legion wiki closeout; current truth now points to Caelestia instead of end4.
