# Report Walkthrough: axiom-desktop-polish-followup

## Mode

Implementation

## Summary

- Fixed Axiom Steam HiDPI integration by pairing scaled-monitor Hyprland XWayland self-scaling with a Steam wrapper default of `STEAM_FORCE_DESKTOPUI_SCALING=1.500000`.
- Replaced generated Caelestia `global, caelestia:*` keybind dispatch with `caelestia shell ...` IPC commands for drawers, brightness, media, and picker actions.
- Replaced the ineffective Axiom literal PATH override with explicit zsh and UWSM/Hyprland session PATH entries for `$HOME/.opencode/bin`.

## Changed Files

- `modules/desktop/hyprland.nix`: adds `.opencode/bin` to generated desktop session PATH, emits `xwayland.force_zero_scaling` for scaled monitors, and routes Caelestia keybinds through CLI IPC.
- `modules/desktop/apps/steam.nix`: derives the active Hyprland monitor scale and applies it to the wrapped Steam launcher through `STEAM_FORCE_DESKTOPUI_SCALING`.
- `hosts/axiom/default.nix`: replaces `environment.variables.PATH = "$HOME/.opencode/bin:$PATH"` with zsh path initialization.
- `.legion/tasks/axiom-desktop-polish-followup/docs/*`: records RFC, RFC review, verification, readiness review, walkthrough, and PR body evidence.

## Why This Shape

- Steam's symptom matches fractional-scale XWayland rendering; forcing XWayland clients to self-scale avoids compositor-side low-resolution stretching, while Steam gets its documented non-integer UI scale knob.
- Caelestia's live failure is on the global-shortcut dispatch path, so keybinds now use the current shell IPC surface instead of keeping the broken dispatcher integration.
- opencode is user-installed outside Nix; this change exposes the existing bin directory without packaging or relocating it.

## Verification

- PASS: targeted Nix eval proved generated zero-scaling, Caelestia IPC keybinds, absence of `global, caelestia:` mappings, and opencode in UWSM/zsh paths.
- PASS: wrapped Steam package build/readback proved `bin/steam` exports `STEAM_FORCE_DESKTOPUI_SCALING=${STEAM_FORCE_DESKTOPUI_SCALING-'1.500000'}`.
- PASS: evaluated package closure still includes Steam, `steam-run`, `steam-gamescope`, `gamescope`, and `gamemode`.
- PASS: assembled Axiom Hyprland config returned `config ok` from `Hyprland --verify-config`.
- PASS: `git diff --check`.
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

Detailed evidence: `docs/test-report.md`.

## Review

Readiness review passed with no blocking findings. Security lens was applied because the change touches session/PATH and user-session command dispatch; no exploitable trust-boundary issue was found.

Detailed review: `docs/review-change.md`.

## Residual Deployment Checks

- Rebuild/switch Axiom, restart the Hyprland session, and confirm Steam renders crisply on the 4K monitor.
- Exercise Caelestia launcher/sidebar/session/media/brightness/screenshot keybinds in the live session.
- Confirm a fresh Axiom shell resolves `opencode` from `$HOME/.opencode/bin/opencode`.
- If Super-key tap-to-launch is missed, split a follow-up for safe Super press/release behavior rather than reintroducing top-level `catchall`.
