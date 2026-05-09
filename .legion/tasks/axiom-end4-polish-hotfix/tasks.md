# Axiom End4 Polish Hotfix Tasks

## Status

- Current stage: verification/review/report/wiki complete; PR lifecycle in progress.
- Execution mode: default implementation mode, low-risk hotfix path.
- Worktree: `.worktrees/axiom-end4-polish-hotfix/`
- Branch: `legion/axiom-end4-polish-hotfix`
- Base ref: `origin/master`

## Checklist

- [x] Confirm narrow hotfix contract with user.
- [x] Materialize `plan.md`, `tasks.md`, and `log.md`.
- [x] Create isolated worktree from `origin/master`.
- [x] Inspect launcher/search focus and IPC path for `Super+Space`.
- [x] Inspect network/Bluetooth icon font or asset path.
- [x] Inspect `Ctrl+Super+T` wallpaper selector preview, preset apply, and theme generation path.
- [x] Enable end4 dock and place it on the far left by default.
- [x] Patch minimal repository-owned Nix/config/import surface.
- [x] Run targeted validation and record `docs/test-report.md`.
- [x] Run readiness review and record `docs/review-change.md`.
- [x] Generate `docs/report-walkthrough.md` and `docs/pr-body.md`.
- [x] Write Legion wiki updates.
- [ ] Commit, push, open PR if required by lifecycle.
- [ ] Follow PR to terminal state, cleanup worktree, refresh main workspace.

## Handoff Notes

- User confirmed all three reported issues are in one low-risk end4 polish hotfix.
- User added that end4 preset wallpapers cannot be applied and theme color switching is not visible; this is included because it shares the `Ctrl+Super+T` wallpaper selector path.
- User also requested enabling the end4 dock and placing it on the far left; keep this to minimal default config changes.
- Keep end4 `ii` active; do not restore the old Axiom shell as primary UI.
- The checkerboard symptoms should be diagnosed rather than assumed to be only a font issue.
