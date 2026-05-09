# Axiom Quickshell Side Dock Regression 任务

## 状态

- 当前阶段：legion-wiki writeback complete；ready for commit/PR lifecycle。
- 执行模式：default implementation low-risk bugfix。
- 范围：修复 PR #14 后 side dock 不显示的 Quickshell QML structure 回归。

## 检查清单

- [x] 收敛回归修复合同。
- [x] 进入 `git-worktree-pr` envelope。
- [x] 加载 `engineer` 并实现最小 QML structure 修复。
- [x] 运行 `verify-change` 并写入 `docs/test-report.md`。
- [x] 运行 `review-change` 并写入 review 结论。
- [x] 生成 walkthrough 和 PR body。
- [x] 执行 Legion wiki 写回。
- [ ] PR merged、worktree cleanup、主工作区 refresh。

## Handoff

- 先检查 `shell.qml` 中 `Variants` 与 `PanelWindow` 的层级。
- 优先修复 structure，不改 notification center business logic。
