# Tasks: axiom-caelestia-keybind-fix

## Status

- Phase: wiki closeout complete; PR lifecycle required.
- Worktree: `.worktrees/axiom-caelestia-keybind-fix/`
- Branch: `legion/axiom-caelestia-keybind-fix`
- PR: pending.

## Checklist

- [x] Materialize task contract for reported Caelestia runtime regressions.
- [x] Remove invalid top-level `catchall` keybind from generated Axiom Hyprland config.
- [x] Add Caelestia icon/MIME runtime packages for checkerboard placeholder icons.
- [x] Verify generated keybind text no longer includes top-level `catchall`.
- [x] Verify Caelestia runtime packages are present in Axiom user packages.
- [x] Run Hyprland parser validation against assembled generated config where available.
- [x] Run Nix build or strongest focused equivalent.
- [x] Complete readiness review.
- [x] Generate report walkthrough and PR body.
- [x] Write Legion wiki closeout.
- [ ] Complete PR lifecycle, cleanup, and main workspace refresh.

## Open Decisions

- Chosen: remove the invalid top-level `catchall` binding instead of introducing a new submap, because this hotfix should not redesign Caelestia launcher behavior.
