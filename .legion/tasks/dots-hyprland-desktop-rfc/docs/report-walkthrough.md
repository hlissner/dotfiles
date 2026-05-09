# Walkthrough: Dots Hyprland Desktop Phase 4

> Mode: implementation
> Task: `.legion/tasks/dots-hyprland-desktop-rfc/`
> Branch: `legion/dots-hyprland-desktop-rfc-phase4-services`

## Reviewer Summary

This change reopens the historical design-only end4 desktop RFC as an implementation task and aligns it with the user-provided `end4.md` direction. The important direction change is that old Axiom dock/guide/button and `autumnal` desktop visuals are no longer compatibility targets; end4 `ii` / `IllogicalImpulseFamily` is the target UX, while Nix remains responsible for host facts, services, dependencies, permissions, and generated-state boundaries.

The implementation is a bounded Phase 4 substrate PR. It does not import the full end4 `ii` tree because `origin/master` still lacks prior Phase 1-3 sources. Instead, it declares the NixOS/user-service substrate that end4 launcher, overview, sidebars, control center, notification center, OSD, wallpaper selector, session/lock, polkit UX, and hardware controls depend on.

## What Changed

- Rewrote task contract and RFC from design-only future planning into current Phase 4 implementation evidence.
- Expanded `modules/desktop/quickshell.nix` with Qt/Kirigami/QML, icons, fonts, clipboard, wallpaper/theme, audio/media, network/Bluetooth, brightness/DDC, power-profile, resource, notification, and fallback control packages.
- Switched clipboard watcher default to end4-compatible `wl-paste --type text --watch cliphist store`, while retaining a rollback backend option.
- Enabled Phase 4 system capabilities: polkit, KDE polkit auth agent, power-profiles-daemon, gnome-keyring without gcr SSH agent, i2c/DDC support, `video`/`input`/`i2c` groups, and Axiom keyring module enablement.
- Removed old Axiom guide entry points from active shell/module paths and deleted the old guide docs/config files.
- Stopped `autumnal` from writing Hyprland desktop visuals by removing the Hyprland import from the autumnal theme module.
- Added transitional helper support for brightness, power profiles, resource status, and `cliphist` search/copy/clear behavior.

## Evidence

- Contract: `.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- RFC: `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC review: `.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- Verification: `.legion/tasks/dots-hyprland-desktop-rfc/docs/test-report.md`
- Change review: `.legion/tasks/dots-hyprland-desktop-rfc/docs/review-change.md`

## Validation

Validation result: PASS with runtime caveats.

- `nix eval` confirmed Phase 4 config wiring: `cliphist` backend, keyring, polkit, power profiles, i2c, i2c group, user groups, removed guide link, and required packages.
- `nix eval` confirmed Material Symbols plus `googlesans-code` mapping, without importing the full `google-fonts` bundle.
- Python helper syntax parse passed for both changed helpers.
- Active shell/module grep found no old guide references in `config/quickshell/axiom-shell/*.qml` or `modules/desktop/*.nix`.
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed after fixing keyring SSH-agent conflict and narrowing the font package.
- Post-review cleanup removed unused `hyprpolkitagent`; targeted eval and toplevel build passed again.

## Review Result

Change review result: PASS.

Security lens was applied for clipboard history, keyring/polkit, user groups, and i2c permissions. No blocking security issue was found. Remaining privacy risk is `cliphist` retention: shell display/readback limits do not prune the database, so retention policy remains a follow-up.

## Runtime Caveats

- Live `systemctl --user restart quickshell.service` was not run because this environment is not the live Axiom graphical session.
- `ii/shell.qml` load was not checked because `origin/master` still lacks the end4 `ii` source tree; this is documented as prior-phase debt.
- Hardware-backed controls were not live-tested: audio, brightness/DDC, NetworkManager, Bluetooth, power profiles, tray, notifications, sidebars, overview, and launcher must be exercised on Axiom hardware after deployment.

## Reviewer Focus

- Check that Phase 4 remains a substrate PR and does not pretend to complete the full end4 `ii` runtime experience.
- Check that the permission additions (`video`, `input`, `i2c`, `i2c-dev`) are acceptable for Axiom's desktop control scope.
- Check that default-on `cliphist` is acceptable for Axiom, given the documented retention caveat and disable/clear controls.
- Check that removing the old Axiom guide and autumnal Hyprland visual hook matches the `end4.md` direction.
