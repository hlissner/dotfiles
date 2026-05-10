# Axiom Caelestia Wallpaper And Launcher Fix Tasks

## Status

- Current phase: PR lifecycle
- Risk: medium
- Mode: default implementation mode

## Checklist

- [x] Capture runtime symptoms and relevant logs.
- [x] Confirm user preference that Caelestia, not `swaybg`, should own wallpaper.
- [x] Materialize task contract.
- [x] Enter isolated worktree / PR envelope for repository changes.
- [x] Complete RFC and review gate.
- [x] Implement Caelestia wallpaper ownership and initial wallpaper seeding.
- [x] Implement service PATH and duplicate-instance protections.
- [x] Update lock/restart integration to avoid observed crash and duplicate shell paths.
- [x] Run static validation and record evidence.
- [x] Run change review.
- [x] Run walkthrough and wiki writeback.

## Open Follow-Up

- Live graphical validation remains required after deployment because static checks cannot prove actual layer rendering or launcher execution inside the running Hyprland session.
