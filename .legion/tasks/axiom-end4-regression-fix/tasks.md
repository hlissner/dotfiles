# Axiom End4 Regression Fix Tasks

## Status

- Current stage: wiki writeback complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk hotfix path.
- Worktree: `.worktrees/axiom-end4-regression-fix/`
- Branch: `legion/axiom-end4-regression-fix-hotkeys-layout`
- Base ref: `origin/master`

## Checklist

- [x] Create isolated worktree from `origin/master`.
- [x] Materialize narrow regression contract.
- [x] Inspect user-session logs and generated config for failure evidence.
- [x] Fix imported `ii` runtime loadability without rolling back to legacy shell.
- [x] Restore `Super+Space` / left sidebar or launcher entrypoint.
- [x] Restore Axiom Colemak keyboard layout in generated Hyprland config.
- [x] Run targeted validation and record test report.
- [x] Run readiness review.
- [x] Generate walkthrough/PR body.
- [x] Write Legion wiki updates.
- [ ] Commit, rebase, push, open PR, enable auto-merge if possible.
- [ ] Follow PR to terminal state, cleanup worktree, refresh main workspace.

## Handoff Notes

- User reports only `Super+Enter` works; `Super+Space` and left sidebar are not usable.
- User reports Colemak keyboard layout no longer applies.
- Keep the end4 `ii` import active and make it load; fix Axiom overrides around it.
