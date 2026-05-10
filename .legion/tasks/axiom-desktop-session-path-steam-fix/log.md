# Log

## 2026-05-10
- User reported that Foot opened from the `axiom` graphical desktop cannot find `git` and `awk`, while SSH login does not reproduce it.
- User also reported Steam does not open, but cannot yet distinguish whether it fails from the GUI launcher only or from a separate Steam runtime issue.
- Contract created with scope focused on declarative graphical session PATH propagation and Steam launchability validation, leaving separate Steam runtime debugging out of scope unless PATH repair disproves the shared-cause assumption.
- Opened git-worktree PR envelope from `origin/master` on branch `legion/axiom-desktop-session-path-steam-fix-session-path` at `.worktrees/axiom-desktop-session-path-steam-fix`.
- RFC and RFC review completed. Decision: export deterministic PATH from generated `uwsm/env`, import `PATH` into systemd user startup, and extend `caelestia-shell.service.path` with generated system packages.
- Implemented `modules/desktop/hyprland.nix` and `modules/desktop/caelestia.nix` changes within the worktree.
- Verification passed: targeted evals for UWSM env, startup hook, Caelestia service path, Steam enablement, `git diff --check`, and full `axiom` toplevel build. See `docs/test-report.md`.
- Change review passed with session security lens. See `docs/review-change.md`.
- Walkthrough, PR body, and wiki writeback completed. See `docs/report-walkthrough.md`, `docs/pr-body.md`, and `.legion/wiki/tasks/axiom-desktop-session-path-steam-fix.md`.
