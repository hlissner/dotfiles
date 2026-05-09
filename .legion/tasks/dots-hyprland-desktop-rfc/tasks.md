# Dots Hyprland Desktop Phase 4 Tasks

## Status

- Current stage: contract restored and being materialized for implementation continuation.
- Execution mode: approved-design continuation after RFC rewrite/review.
- Scope: Phase 4 declarative end4 service capabilities plus RFC/theme realignment.
- Worktree: `.worktrees/dots-hyprland-desktop-rfc/`
- Branch: `legion/dots-hyprland-desktop-rfc-phase4-services`
- Base ref: `origin/master`

## Checklist

- [x] Restore historical `dots-hyprland-desktop-rfc` task context.
- [x] Detect contract drift from design-only RFC to Phase 4 implementation.
- [x] Open mandatory Legion worktree from `origin/master`.
- [x] Rewrite `plan.md` and `tasks.md` for current implementation contract.
- [x] Rewrite `docs/rfc.md` around `end4.md` phase/theme truth.
- [x] Review the rewritten RFC.
- [x] Inspect current Phase 1-3 implementation state in the worktree.
- [x] Implement Phase 4 Nix/service/dependency changes.
- [x] Run and record verification in `docs/test-report.md`.
- [x] Run change review and record readiness/blockers.
- [x] Generate delivery walkthrough and PR body.
- [x] Write Legion wiki updates.
- [ ] Commit implementation branch.
- [ ] Rebase on `origin/master`, push branch, open/update PR, and attempt auto-merge.
- [ ] Follow PR checks/review to terminal state or record blocked handoff.
- [ ] Cleanup worktree and refresh main workspace after PR terminal state.

## Handoff Notes

- `end4.md` is an input supplied in the main workspace and is authoritative for this continuation; its requirements have been folded into `plan.md`/`docs/rfc.md` rather than relying on an untracked file in the PR.
- Old Axiom dock/guide/button preservation and `autumnal` desktop fallback are no longer compatibility requirements.
- Keep Phase 5 visual automation and Phase 6 AI out of implementation scope unless needed to keep existing Phase 4 shell code loading.
