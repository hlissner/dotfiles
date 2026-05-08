# Dotfiles Wayland Runtime Fixes Tasks

## Status

- Current phase: implementation discovery
- Base ref: `origin/master`
- Branch: `legion/dotfiles-wayland-runtime-fixes`
- Worktree: `.worktrees/dotfiles-wayland-runtime-fixes/`

## Checklist

- [x] Stabilize task contract.
- [x] Create isolated worktree from latest `origin/master`.
- [x] Materialize `plan.md`, `tasks.md`, and `log.md`.
- [x] Inspect Hyprland/UWSM session entries and greetd command.
- [x] Inspect `axiom` NetworkManager/iwd/resolved ownership.
- [x] Implement minimal runtime fixes.
- [x] Run actual `axiom` toplevel build.
- [x] Run targeted session and network evaluations.
- [x] Write `docs/test-report.md`.
- [x] Run readiness review and write `docs/review-change.md`.
- [x] Write reviewer walkthrough and PR body.
- [x] Update Legion wiki.
- [ ] Commit, rebase, push, create/merge PR.
- [ ] Clean up worktree and refresh main workspace.

## Acceptance Tracking

- Hyprland session command points at a real evaluated desktop entry: pass.
- NetworkManager + iwd + resolved ownership is coherent: pass.
- `axiom` toplevel build passes: pass.
- Verification, review, walkthrough, and wiki evidence exist: pass.
- PR terminal state, cleanup, and main refresh complete: pending.
