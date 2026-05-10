# RFC: Axiom Caelestia Wallpaper And Launcher Runtime Fix

## Context

The Caelestia migration made Caelestia the current shell direction, but live Axiom logs show several integration gaps after switching to `caelestia-dots/shell`:

- Hyprland still starts `swaybg` for `/home/c1/the-great-sage.jpg` while Caelestia also creates `caelestia-background` layers.
- Caelestia starts without `/home/c1/.local/state/caelestia/wallpaper/path.txt`, so its background layer is not initialized from the host wallpaper policy.
- The systemd user unit has a minimal PATH and cannot find helper commands that Caelestia invokes from QML.
- An unmanaged duplicate quickshell instance can run alongside the systemd service, causing duplicate layer surfaces and duplicate global shortcuts.
- `loginctl lock-session` triggers Caelestia lock handling, which currently crashes with Wayland fatal errors in the live session.

The user confirmed Caelestia should own wallpaper, not `swaybg`.

## Options

### Option A: Keep `swaybg` As Wallpaper Owner

This would disable Caelestia wallpaper rendering and continue using the existing Hyprland startup hook.

- Pros: Small change and avoids Caelestia image decoding issues.
- Cons: Contradicts the user preference and leaves Caelestia's wallpaper UI/state detached from the actual desktop background.

### Option B: Make Caelestia The Wallpaper Owner

This gates the Hyprland `swaybg` hook when Caelestia is enabled, seeds Caelestia's wallpaper state from the host wallpaper policy, and keeps Caelestia responsible for background rendering.

- Pros: Matches user preference and aligns launcher wallpaper controls with the real wallpaper owner.
- Cons: Depends on Caelestia's image decode behavior for the existing large JPG and needs live validation.

### Option C: Keep Both Owners With Ordering Tweaks

This would try to preserve `swaybg` and Caelestia simultaneously while tuning order or layer behavior.

- Pros: Superficially minimizes removal.
- Cons: Keeps the core layering race, makes boot visuals nondeterministic, and complicates debugging.

## Decision

Use Option B.

Caelestia should own wallpaper for the Caelestia desktop session. Hyprland should not start `swaybg` when Caelestia is enabled and configured to own wallpaper. The integration should seed Caelestia's state file with the host wallpaper path so first boot is deterministic.

## Implementation Plan

- Add a Caelestia module option for wallpaper ownership or derive it from the enabled Caelestia module with a safe default for Axiom.
- Generate `caelestia/wallpaper/path.txt` from the primary host wallpaper path when Caelestia owns wallpaper.
- Gate the Hyprland `startup."10-wallpaper"` and reload hook so `swaybg` is skipped when Caelestia owns wallpaper.
- Add `--no-duplicate` to the Caelestia shell service invocation and route restart/stop keybinds through `systemctl --user` instead of spawning `$caelestiaShell` directly.
- Add an explicit service PATH for QML-spawned helper processes: at minimum `app2unit`, `util-linux` for `lsblk`, the Caelestia CLI, and current-system/profile bins needed for desktop entry execution.
- Change ordinary lock keybind/idle paths away from `loginctl lock-session` and toward `hyprlock` while the Caelestia logind lock path is unstable.

## Verification

- Evaluate or build Axiom configuration to ensure Nix option wiring is valid.
- Inspect rendered `caelestia/shell.json` and `caelestia/wallpaper/path.txt` content.
- Inspect rendered Hyprland custom config to verify `swaybg` is gated and restart/lock keybinds use the intended commands.
- Inspect rendered `caelestia-shell.service` to verify `--no-duplicate` and PATH content.
- Record live follow-up: after deploy, restart/cleanup duplicate shell, verify only one `quickshell` instance, verify `hyprctl layers -j` shows one Caelestia background owner, and verify launcher starts Zen from Enter.

## Rollback

- Re-enable the Hyprland `swaybg` hook and remove Caelestia wallpaper state seeding if Caelestia cannot reliably render the wallpaper.
- Revert lock keybind/idle routing to previous logind behavior only after the Caelestia lock crash is resolved upstream or by a local patch.
- Keep service PATH and duplicate-instance protections unless they introduce a concrete regression; they address independent runtime bugs.

## Open Risks

- `/home/c1/the-great-sage.jpg` may still exceed Caelestia's image cache allocation limits. If that occurs, follow-up should provide a display-sized generated wallpaper asset or adjust Caelestia image handling.
- Static validation cannot prove live Wayland layer behavior. A post-deploy live check remains mandatory.
