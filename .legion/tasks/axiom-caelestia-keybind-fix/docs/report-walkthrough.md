# Report Walkthrough: axiom-caelestia-keybind-fix

## Mode

Implementation.

## What Changed

- Removed the invalid generated Hyprland binding `bindin = Super, catchall, global, caelestia:launcherInterrupt` from `modules/desktop/hyprland.nix`.
- Kept the normal Caelestia launcher binding and explicit mouse interrupt bindings.
- Added `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils` to the local Caelestia integration's Linux user packages for icon/MIME fallback data.
- Did not reintroduce end4, legacy Quickshell, fuzzel fallback, or broader keybind redesign.

## Why

Hyprland rejects `catchall` outside submaps. The Caelestia migration generated that binding at top level in `hypr/custom/keybinds.conf`, causing the user-reported config parse error and blocking clean Hyprland config load. The user also reported checkerboard placeholder icons; the local integration now exposes the standard icon theme and MIME data packages that Caelestia's UI can rely on at runtime.

## Validation Evidence

- PASS: generated `hypr/custom/keybinds.conf` eval no longer contains `catchall`.
- PASS: source regression search found no `catchall` in `modules/desktop/*.nix`.
- PASS: Axiom evaluated user packages include the Caelestia shell/CLI plus `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils`.
- PASS: assembled Axiom Hyprland config parsed with `Hyprland --verify-config` and returned `config ok`.
- PASS: `git diff --check`.
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

Detailed evidence: `.legion/tasks/axiom-caelestia-keybind-fix/docs/test-report.md`.

## Review Evidence

Readiness review passed with no blocking findings. Security lens was considered for global keybindings; the change removes a catchall binding and adds no new privileged action or user-input execution path.

Detailed review: `.legion/tasks/axiom-caelestia-keybind-fix/docs/review-change.md`.

## Residual Risk

- Live Caelestia launcher interruption behavior and icon rendering were not tested in a graphical session. This hotfix is still ready because the failing Hyprland parser surface is directly verified and the icon/MIME package closure is present in evaluation.
