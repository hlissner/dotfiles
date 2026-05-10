# Report Walkthrough: Axiom Caelestia Wallpaper And Launcher Fix

## Mode

implementation

## What Changed

- Added `modules.desktop.caelestia.wallpaper` ownership controls and enabled Caelestia wallpaper ownership for Axiom.
- Seeded Caelestia's mutable wallpaper state from the service startup path when the state file is missing or empty.
- Gated the Hyprland `swaybg` startup/reload hook when Caelestia owns wallpaper, removing the dual wallpaper owner race.
- Added `--no-duplicate` and an explicit service PATH to `caelestia-shell.service` so launcher/helper subprocesses can find `app2unit`, `lsblk`, Zen, Foot, and user application commands.
- Changed shell restart keybinds to systemd-owned stop/restart commands and changed ordinary lock paths to `hyprlock` to avoid the observed Caelestia logind lock crash path.

## Evidence

- Design source: `docs/rfc.md`
- RFC review: `docs/review-rfc.md` PASS
- Verification: `docs/test-report.md` PASS
- Change review: `docs/review-change.md` PASS

## Validation Summary

- Targeted Nix eval confirmed Axiom has Caelestia wallpaper enabled, `/home/c1/the-great-sage.jpg` selected, no `10-wallpaper` `swaybg` startup hook, `--no-duplicate`, service PATH coverage for app launcher/runtime commands, systemd restart keybinds, and hyprlock lock routing.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure` completed successfully.

## Reviewer Notes

- The wallpaper state seed intentionally does not overwrite an existing non-empty `path.txt`, so user-selected Caelestia wallpaper state remains mutable after first seed.
- Live session cleanup is still needed after deployment: stop the existing unmanaged quickshell instance, restart `caelestia-shell.service`, and confirm only one Caelestia background layer remains.
- If the live session still shows image decode failures for `/home/c1/the-great-sage.jpg`, the follow-up should generate a display-sized wallpaper asset while keeping Caelestia as owner.
