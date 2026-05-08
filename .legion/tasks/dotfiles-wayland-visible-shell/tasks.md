# Dotfiles Wayland Visible Shell Tasks

## Status

- Current phase: PR lifecycle
- Base ref: `origin/master`
- Branch: `legion/dotfiles-wayland-visible-shell`
- Worktree: `.worktrees/dotfiles-wayland-visible-shell/`

## Checklist

- [x] Stabilize task contract.
- [x] Create isolated worktree from latest `origin/master`.
- [x] Materialize `plan.md`, `tasks.md`, and `log.md`.
- [x] Inspect Hyprland startup hook and generated config.
- [x] Inspect DMS/Quickshell user services and target wiring.
- [x] Inspect wallpaper/background startup path.
- [x] Implement minimal visible-shell bootstrap fix.
- [x] Run actual `axiom` toplevel build.
- [x] Run targeted shell startup evaluations.
- [x] Write `docs/test-report.md`.
- [x] Run readiness review and write `docs/review-change.md`.
- [x] Write reviewer walkthrough and PR body.
- [x] Update Legion wiki.
- [ ] Commit, rebase, push, create/merge PR.
- [ ] Clean up worktree and refresh main workspace.

## Acceptance Tracking

- Visible shell/background startup is connected to Hyprland session: pass.
- DMS/Quickshell user service wiring is coherent: pass.
- `axiom` toplevel build passes: pass.
- Verification, review, walkthrough, and wiki evidence exist: pass.
- PR terminal state, cleanup, and main refresh complete: pending.
