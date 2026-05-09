## Summary

- Adds Stage 3 Quickshell-owned quick controls for audio, network, Bluetooth, media, session/power, and basic desktop actions while keeping external fallback tools visible.
- Adds Quickshell OSD routing for volume/brightness/media feedback without replacing existing `hey .osd` / `playerctl` fallback behavior.
- Keeps Quickshell service ownership in Nix and limits Hyprland changes to keybinding routing.

## Verification

- PASS: helper syntax/smoke, OSD zsh syntax, `git diff --check`, Nix parse/eval/build, Hyprland `--verify-config`, Quickshell CLI, QML lint, scope/fallback greps, Variants composition, helper subprocess-shape check.
- Full Axiom build passed for `.#nixosConfigurations.axiom.config.system.build.toplevel`.

## Risks / Gaps

- Live Quickshell/layer-shell panel behavior and OSD IPC rendering could not be proven headlessly because no usable display was available.
- Wi-Fi/Bluetooth toggles, volume mutation, lock, DPMS off, and `wlogout` launch were intentionally not executed during verification.
- Real-session behavior may vary with `nmcli`, `bluetoothctl`, `pamixer`, `playerctl`, and device/service availability; fallbacks remain available.

## Rollback

- Revert this PR or switch to the previous NixOS generation.
- Minimal rollback: restore dock controls and media keys to the previous direct external commands / `hey .osd` / `playerctl` paths.
- OSD-only rollback: force `hey .osd` / `notify-send` fallback if Quickshell IPC is unreliable.
