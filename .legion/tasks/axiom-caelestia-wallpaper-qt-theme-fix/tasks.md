# Axiom Caelestia Wallpaper Qt Theme Fix Tasks

## Status

- Current phase: PR lifecycle
- Risk: medium
- Mode: default implementation mode

## Checklist

- [x] Capture prior follow-up evidence from the wallpaper/launcher fix task.
- [x] Capture upstream `caelestia-dots/shell#1282` Qt platform theme guidance.
- [x] Materialize follow-up task contract.
- [x] Enter isolated worktree / PR envelope for repository changes.
- [x] Draft RFC for wallpaper decode and Qt theme fixes.
- [x] Pass RFC review gate.
- [x] Implement decode-safe Caelestia wallpaper path.
- [x] Implement `QT_QPA_PLATFORMTHEME=qt6ct` session environment and package support.
- [x] Run static validation and record evidence.
- [x] Run change review.
- [x] Generate walkthrough and PR body.
- [x] Run wiki writeback.
- [ ] Merge PR, clean up worktree, and refresh main workspace.

## Open Follow-Up

- Live graphical validation after deployment must confirm the wallpaper renders, no `swaybg` process owns wallpaper, one Caelestia shell instance is active, and launcher icons no longer render as color blocks.
