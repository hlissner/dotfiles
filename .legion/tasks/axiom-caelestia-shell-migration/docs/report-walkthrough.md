# Report Walkthrough: axiom-caelestia-shell-migration

Date: 2026-05-10
Mode: implementation

## Reviewer Summary

This delivery migrates Axiom's active Wayland shell from the vendored end4 `ii`/legacy Quickshell path to Caelestia Shell using Caelestia's upstream Nix package with CLI support. The implementation keeps this repository in charge of NixOS integration, Hyprland session ownership, generated XDG config, host facts, and rollback through Nix generations.

Read this as an implementation review packet, not a new design proposal. The design was approved in `docs/rfc.md`, verification is recorded in `docs/test-report.md`, and readiness review passed in `docs/review-change.md`.

## What Changed

- Added the `github:caelestia-dots/shell` flake input following `nixpkgs-unstable` and consumes the upstream `with-cli` package for Linux desktop use.
- Replaced the end4-specific Quickshell integration with a local `modules/desktop/caelestia.nix` boundary that owns package exposure, `caelestia-shell.service`, and generated `~/.config/caelestia/shell.json`.
- Reworked Hyprland integration so the checked-in base config sources repository-owned generated/local files while Axiom monitor, workspace, input, app, rule, and keybind facts remain Nix-generated.
- Removed active end4 runtime/config trees including `config/quickshell`, `config/matugen`, `config/fuzzel`, and imported end4 Hyprland shell config.
- Updated README desktop truth from Quickshell/Fuzzel toward Caelestia Shell.

## Evidence Map

- Task contract and acceptance criteria: `.legion/tasks/axiom-caelestia-shell-migration/plan.md`
- Approved migration design and deletion boundary: `.legion/tasks/axiom-caelestia-shell-migration/docs/rfc.md`
- Verification results: `.legion/tasks/axiom-caelestia-shell-migration/docs/test-report.md`
- Readiness/security review: `.legion/tasks/axiom-caelestia-shell-migration/docs/review-change.md`
- Implementation timeline: `.legion/tasks/axiom-caelestia-shell-migration/log.md`

## Validation Status

Static and Nix validation passed:

- Upstream Caelestia `with-cli` package evaluated as available.
- Axiom `caelestia-shell.service` evaluates to `/nix/store/...-caelestia-shell-1.0.0/bin/caelestia-shell`.
- Generated `caelestia/shell.json` contains minimal Nix-owned defaults and disables dangerous launcher actions.
- Generated Hyprland keybinds point at Caelestia global shortcuts and CLI-backed commands.
- User packages include Caelestia shell and CLI.
- Active source scan over `config`, `modules`, and `README.md` found no legacy end4/`ii` runtime references for the targeted patterns.
- `git diff --check` passed.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

Live graphical smoke was skipped because the automation shell did not have `WAYLAND_DISPLAY` or `HYPRLAND_INSTANCE_SIGNATURE`.

## Review Decision

`docs/review-change.md` records PASS with no blocking correctness, maintainability, scope, or security/privacy findings.

The security/privacy lens specifically covered the new third-party desktop shell/CLI and screenshot, recording, clipboard, launcher, and global-shortcut entrypoints. The review found no new exploitable local trust-boundary issue: upstream code is pinned through `flake.lock`, no secrets are added, and dangerous launcher actions are disabled in generated config.

## Residual Follow-ups

- After deployment in a real Hyprland session, smoke test panel rendering, global shortcut delivery, launcher/sidebar/session UI, screenshot/record/clipboard flows, tray, and OSD behavior.
- Run `Hyprland --verify-config` from a live or assembled Home Manager config tree if available.
- Complete Legion wiki current-truth writeback so future work treats Caelestia, not end4, as the active desktop shell direction.
