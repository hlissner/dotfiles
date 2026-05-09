# Dots Hyprland Desktop Complete End4 Tasks

## Status

- Current stage: wiki writeback complete; commit/PR lifecycle pending.
- Execution mode: default implementation mode with RFC update/review gate.
- Scope: import and wire upstream end4 `ii`, matugen/theme, Hyprland layering, and Phase 4 core surfaces; substrate-only is not acceptable.
- Worktree: `.worktrees/dots-hyprland-desktop-rfc/`
- Branch: `legion/dots-hyprland-desktop-rfc-end4-complete`
- Base ref: `origin/master`

## Checklist

- [x] Restore the existing `dots-hyprland-desktop-rfc` task.
- [x] Identify substrate-only contract drift after user rejection.
- [x] Open mandatory Legion worktree from `origin/master`.
- [x] Rewrite `plan.md` and `tasks.md` for complete end4 import.
- [x] Rewrite RFC for direct upstream import and no-downgrade acceptance.
- [x] Review the rewritten RFC.
- [x] Fetch upstream `end-4/dots-hyprland` in the worktree.
- [x] Import `ii` Quickshell source and required adjacent config/scripts.
- [x] Import matugen/theme/wallpaper chain sources.
- [x] Import end4 Hyprland layering and add Axiom/Nix overrides.
- [x] Make Axiom Quickshell default load `ii/shell.qml`.
- [x] Remove or demote old `axiom-shell` runtime path.
- [x] Run and record verification in `docs/test-report.md`.
- [x] Run change review and record readiness/blockers.
- [x] Generate delivery walkthrough and PR body.
- [x] Write Legion wiki updates.
- [ ] Commit implementation branch.
- [ ] Rebase on `origin/master`, push branch, open/update PR, and attempt auto-merge.
- [ ] Follow PR checks/review to terminal state or record blocked handoff.
- [ ] Cleanup worktree and refresh main workspace after PR terminal state.

## Handoff Notes

- User explicitly rejected the prior Phase 4 substrate-only downgrade.
- Upstream source is `https://github.com/end-4/dots-hyprland`.
- Hostname `axiom` does not imply the tool shell is in a graphical Hyprland session; live checks must record actual session variables.
