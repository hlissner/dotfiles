# RFC Review: Axiom Caelestia Wallpaper And Launcher Runtime Fix

## Decision

PASS

## Findings

- No blocking scope issue found. The RFC correctly narrows wallpaper ownership to Caelestia for this task and avoids the dual-owner `swaybg` plus Caelestia layer race.
- No blocking verification issue found. The proposed checks cover rendered Caelestia state, rendered Hyprland hooks/keybinds, and systemd service PATH/duplicate protection. Live validation is explicitly left as a post-deploy requirement.
- No blocking rollback issue found. Re-enabling `swaybg` and removing Caelestia wallpaper seeding is a clear rollback path if Caelestia cannot render the large JPG reliably.

## Implementation Notes

- Seed the Caelestia wallpaper state from the service startup path only when the state file is missing or empty. Do not manage `/home/c1/.local/state/caelestia/wallpaper/path.txt` as an immutable home-manager file because Caelestia needs to update that state when wallpaper changes.
- Keep the service PATH fix independent of wallpaper ownership. Launcher app execution and helper process failures are separate from the background-layer problem.

## Residual Risk

- The existing `/home/c1/the-great-sage.jpg` may still exceed Caelestia/Qt image decode limits in some UI paths. If live validation confirms this, follow-up should produce a display-sized wallpaper asset or patch upstream image handling.
