# Walkthrough: Axiom Caelestia Wallpaper Qt Theme Fix

## Mode

Implementation.

## Summary

- Keeps Caelestia as Axiom's wallpaper owner while making the configured wallpaper decode-safe for Caelestia/Qt.
- Applies the upstream Caelestia issue #1282 workaround by setting `QT_QPA_PLATFORMTHEME=qt6ct` in the repo-owned session and service environments.
- Preserves live user choice by only rewriting Caelestia `path.txt` when it is missing, empty, or still points at the oversized canonical source image.

## What Changed

### Decode-Safe Wallpaper

`modules/desktop/caelestia.nix` now generates `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` from `/home/c1/the-great-sage.jpg` during `caelestia-shell.service` pre-start.

The derivative is bounded with ImageMagick using `-resize '3840x2160>'`, preserving aspect ratio and avoiding the observed Qt `256 MB` decoded allocation failure. The source image remains the canonical host wallpaper policy input.

The seed script updates `path.txt` only when the current value is missing, empty, or equal to `/home/c1/the-great-sage.jpg`, so a manually selected different wallpaper is not overwritten.

### Qt Platform Theme

`modules/desktop/caelestia.nix` sets `QT_QPA_PLATFORMTHEME=qt6ct` for the Caelestia systemd user service and adds `pkgs.unstable.qt6Packages.qt6ct` to Caelestia user packages.

`modules/desktop/hyprland.nix` sets the same platform theme in generated Hyprland env, generated UWSM env, global Hyprland session variables, and imports it into the systemd user manager environment at session startup.

## Evidence

- RFC: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/rfc.md`
- RFC review: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/review-rfc.md`
- Verification: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/test-report.md`
- Change review: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/review-change.md`

## Verification Summary

- Targeted `nix eval --impure --json --expr ...` passed and confirmed generated Hyprland/UWSM env, service env, startup import hook, `ExecStartPre`, and `qt6ct` package inclusion.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure` passed.
- ImageMagick smoke test passed, converting `/home/c1/the-great-sage.jpg` to a `3840x1858` `757392B` derivative with the same transform used by the service script.

## Review Summary

Change review passed with security lens applied to user-session environment and runtime state generation. No blocking findings were found.

Non-blocking hardening note: the state directory could be made `0700` and `path.txt` could be written atomically in a later cleanup, but current behavior is not a privilege-boundary issue because the script runs as the user.

## Deployment Notes

- A full Hyprland restart is required to validate the `QT_QPA_PLATFORMTHEME=qt6ct` launcher icon workaround for newly started processes.
- Live validation should confirm `path.txt` points to `generated.jpg` unless a different wallpaper was manually selected.
- Live validation should confirm Caelestia logs no longer show the Qt allocation rejection, `swaybg` remains absent, one Caelestia quickshell instance is active, and launcher icons render normally.
