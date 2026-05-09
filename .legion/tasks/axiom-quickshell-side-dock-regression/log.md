# Axiom Quickshell Side Dock Regression 日志

## 2026-05-09

- 用户报告 PR #14 后左侧 side dock 不见。
- 按 Legion workflow 创建低风险 bugfix 任务，目标是恢复 side dock，同时保留 notification center。
- 进入 `git-worktree-pr` envelope。base ref：`origin/master` @ `adba539988a1ba86ad6c2e5544ebb19795121e59`；branch：`legion/axiom-quickshell-side-dock-regression-fix`；worktree：`.worktrees/axiom-quickshell-side-dock-regression/`。
- engineer 修复完成：将原 side dock `PanelWindow` 和 notification panel `PanelWindow` 拆到两个独立 `Variants { model: Quickshell.screens }` block，避免同一个 `Variants` 中多个 sibling delegate 导致 dock 不显示。
- verify-change 完成并写入 `docs/test-report.md`：`git diff --cached --check` 通过；QML structure grep 确认两个独立 `Variants`；service ownership eval 仍绑定 `hyprland-session.target`；Axiom toplevel build 通过；headless/offscreen Quickshell smoke 仍受无 PanelWindow backend 限制。
- review-change 完成并写入 `docs/review-change.md`：PASS，无 blocking findings；安全边界未变化；真实 Axiom session 可见性仍是残余人工验收项。
- report-walkthrough 完成并写入 `docs/report-walkthrough.md` 和 `docs/pr-body.md`。
- legion-wiki 写回完成：新增 `.legion/wiki/tasks/axiom-quickshell-side-dock-regression.md`，更新 `index.md`、`patterns.md` 和 `log.md`。
