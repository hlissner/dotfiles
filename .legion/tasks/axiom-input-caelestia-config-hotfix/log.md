# Axiom Input And Caelestia Config Hotfix - 日志

## 会话进展 (2026-05-10)

### ✅ 已完成

- Created a scoped Legion contract for the reported Axiom keyboard layout/Super-key regression and mutable Caelestia `shell.json` request.
- Opened isolated worktree `.worktrees/axiom-input-caelestia-config-hotfix` on branch `legion/axiom-input-caelestia-config-hotfix` from `origin/master`.
- Implemented the scoped hotfix: generated Hyprland keybind modifiers are canonical uppercase tokens, Caelestia defaults suppress keyboard layout toasts, and `shell.json` is seeded as a writable user file from the Caelestia service pre-start path.
- Engineer smoke eval passed for uppercase `SUPER` keybinds, retained Colemak input facts, absence of Home Manager ownership for `caelestia/shell.json`, and shell/wallpaper pre-start scripts in the Caelestia service.
- Completed verify-change with focused Nix eval assertions, seed script/JSON inspection, assembled Hyprland parser validation, and an Axiom toplevel build. Evidence is in `docs/test-report.md`.
- Completed read-only review-change with PASS. The review found no blocking findings and recorded the mutable-config security lens plus live-session residual risks in `docs/review-change.md`.
- Generated implementation-mode walkthrough and PR body artifacts in `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed Legion wiki writeback for the task summary, mutable seeded `shell.json` decision/pattern, canonical Hyprland modifier policy, and post-deploy Super-key/layout-toast maintenance smoke.
- Committed branch `legion/axiom-input-caelestia-config-hotfix` and opened PR https://github.com/Thrimbda/dotfiles/pull/33.
- PR lifecycle: auto-merge could not be enabled because the repository does not allow it; required checks reported none; PR is clean and open with no blocking review decision.

### 🟡 进行中

- Continue PR checks/review/auto-merge lifecycle for https://github.com/Thrimbda/dotfiles/pull/33.

### ⚠️ 阻塞/待定

- Live Hyprland Super-key behavior requires post-deploy session smoke if it cannot be exercised in automation.

---

## 关键文件

- `modules/desktop/hyprland.nix` - generated keybind and input config.
- `modules/desktop/caelestia.nix` - shell settings, service ownership, and config seeding.

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Treat `shell.json` as a mutable seeded user config instead of a Home Manager-owned immutable file. | The user explicitly needs to edit the file, while the repository still needs a default seed for new deployments. | Keep Home Manager ownership and accept read-only behavior. | 2026-05-10 |
| Canonicalize Hyprland modifier tokens before deeper input-stack changes. | It is the smallest repo-owned fix for a Super-key recognition regression and is statically verifiable. | Change XKB layout/variant or debug hardware/firmware in the same task. | 2026-05-10 |

---

## 快速交接

**下次继续从这里开始：**

1. Patch `modules/desktop/hyprland.nix` and `modules/desktop/caelestia.nix` in the worktree.
2. Run focused Nix evals, Hyprland parser validation, and build/static checks.
3. Complete review, walkthrough, wiki writeback, commit, PR lifecycle, and cleanup.

**注意事项：**

- Main workspace had pre-existing uncommitted changes before this worktree was created: `hosts/axiom/default.nix` and `end4.md`. Do not modify or revert them from this task.

---

*最后更新: 2026-05-10 23:48 by OpenCode*
