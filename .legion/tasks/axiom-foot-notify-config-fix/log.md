# Axiom Foot Notify Config Fix Log

## 2026-05-09

- User reported Foot aborts at startup because `/home/c1/.config/foot/foot.global.ini` contains invalid `[main].notify`.
- Opened mandatory isolated worktree `.worktrees/axiom-foot-notify-config-fix/` on branch `legion/axiom-foot-notify-config-fix` from `origin/master`.
- Materialized a narrow low-risk hotfix contract: restore Foot startup by removing or replacing the unsupported option, without changing the default terminal or mutating live home state.
- Located `modules/desktop/term/foot.nix`: generated `foot.global.ini` is sourced from repository file `config/foot/foot.ini`.
- Reproduced the reported failure with `foot --check-config --config config/foot/foot.ini`; Foot 1.25.0 rejects `[main].notify` as an invalid option.
- Removed the unsupported `notify` key from `config/foot/foot.ini` as the minimal compatibility fix.
- Recorded `docs/test-report.md`. Direct Foot config validation, Nix-evaluated `foot.global.ini` source validation, `git diff --check`, and full Axiom toplevel build passed.
- Change review PASS with no blockers. Review confirmed the fix is scoped to the source file linked as `foot.global.ini`, removes only the invalid key, and has no material security trigger.
- Generated reviewer walkthrough and PR body: `docs/report-walkthrough.md`, `docs/pr-body.md`.
- Completed Legion wiki writeback with task summary, terminal config validation pattern, and Foot notification follow-up.
