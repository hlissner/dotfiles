# Axiom Foot Notify Config Fix Tasks

## Status

- Current stage: wiki writeback complete; PR lifecycle pending.
- Execution mode: default implementation mode, low-risk hotfix path.
- Worktree: `.worktrees/axiom-foot-notify-config-fix/`
- Branch: `legion/axiom-foot-notify-config-fix`
- Base ref: `origin/master`

## Checklist

- [x] Create isolated worktree from `origin/master`.
- [x] Materialize narrow Foot config regression contract.
- [x] Locate the repository source for `foot.global.ini`.
- [x] Patch the invalid Foot `notify` option.
- [x] Run targeted Foot config validation and record test report.
- [x] Run readiness review.
- [x] Generate walkthrough/PR body.
- [x] Write Legion wiki updates.
- [ ] Commit, rebase, push, open PR, enable auto-merge if possible.
- [ ] Follow PR to terminal state, cleanup worktree, refresh main workspace.

## Handoff Notes

- Reported live error: `foot: /home/c1/.config/foot/foot.global.ini:5: [main].notify: notify-send -a ${app-id} -i ${app-id} ${title} ${body}: not a valid option: notify`.
- Keep the fix scoped to Foot startup compatibility.
