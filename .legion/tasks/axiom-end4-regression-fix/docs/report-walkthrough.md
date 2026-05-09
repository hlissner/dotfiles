# Walkthrough: Axiom End4 Regression Fix

> Mode: implementation
> Task: `.legion/tasks/axiom-end4-regression-fix/`
> Evidence only: this summarizes existing task evidence and does not add new validation.

## Reviewer Summary

This fixes the first live regressions found after the complete end4 import without rolling back to the legacy shell. The root cause for missing shell surfaces was not just a keybind issue: live `quickshell.service` logs showed imported `ii` failed to load because `org.kde.kirigami` was unavailable. The patch wires the actual Kirigami QML module into the wrapped Quickshell runtime, restores Axiom's Colemak XKB facts after upstream Hyprland defaults, and adds host-level end4 IPC hotkeys for `Super+Space` and `Super+A`.

## What Changed

- `modules/desktop/quickshell.nix` now includes `kdePackages.kirigami.unwrapped` in QML import paths and exports both `QML2_IMPORT_PATH` and `QML_IMPORT_PATH` from the wrapper.
- `modules/desktop/hyprland.nix` now generates an `input` override in `hypr/custom/general.conf` from Nix-owned XKB facts, so Axiom evaluates to `kb_layout = us`, `kb_variant = colemak`, and `kb_options = terminate:ctrl_alt_bksp`.
- `modules/desktop/hyprland.nix` now generates direct host hotkeys: `Super+Space` calls end4 `search toggle`, and `Super+A` calls end4 `sidebarLeft toggle`.

## Evidence

- Live failure: `journalctl --user -u quickshell.service -b` showed `module "org.kde.kirigami" is not installed` through `WaffleFamily -> FluentIcon`.
- PASS: generated Hyprland general config eval includes Colemak XKB facts.
- PASS: generated Hyprland keybind config eval includes `Super+Space` and `Super+A` end4 IPC commands.
- PASS: wrapped Quickshell package build.
- PASS: Kirigami QML module path exists in the unwrapped package.
- PASS: Quickshell service `ExecStart` points at the new wrapped package with `--config ii`.
- EXPECTED HEADLESS LIMITATION: offscreen smoke reaches `ii/shell.qml` and fails at `No PanelWindow backend loaded`.
- PASS: full Axiom toplevel build.
- PASS: change review, no blockers.

## Residual Risk

- The fixed generation still needs live switch/restart on Axiom, followed by `quickshell.service` journal inspection.
- `Super+Space`, `Super+A`, and Colemak behavior still need live Hyprland confirmation after deployment.
