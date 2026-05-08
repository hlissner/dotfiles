# Dotfiles Wayland Runtime Follow-up Tasks

## Status

- Current phase: implementation discovery
- Base ref: `origin/master`
- Branch: `legion/dotfiles-wayland-runtime-followup`
- Worktree: `.worktrees/dotfiles-wayland-runtime-followup/`

## Checklist

- [x] Stabilize task contract.
- [x] Create isolated worktree from latest `origin/master`.
- [x] Materialize `plan.md`, `tasks.md`, and `log.md`.
- [x] Inspect generated Hyprland rule syntax.
- [x] Inspect effective `axiom` NetworkManager/iwd/resolved startup settings.
- [x] Implement minimal runtime fixes.
- [x] Run actual `axiom` toplevel build.
- [x] Run targeted Hyprland/network evaluations.
- [x] Write `docs/test-report.md`.
- [x] Run readiness review and write `docs/review-change.md`.
- [x] Write reviewer walkthrough and PR body.
- [x] Update Legion wiki.
- [ ] Commit, rebase, push, create/merge PR.
- [ ] Clean up worktree and refresh main workspace.

## Acceptance Tracking

- Hyprland config uses non-deprecated supported rule syntax: pass.
- NetworkManager + iwd + resolved startup defaults are coherent: pass.
- `axiom` toplevel build passes: pass.
- Verification, review, walkthrough, and wiki evidence exist: pass.
- PR terminal state, cleanup, and main refresh complete: pending.
