# Axiom Quickshell Notification Center 任务

## 状态

- 当前阶段：legion-wiki writeback complete；ready for commit/PR lifecycle。
- 执行模式：approved-design continuation，基于已 PASS 的 `dots-hyprland-desktop-rfc`。
- 范围：RFC Stage 1 only；实现 session-local notification center。

## 检查清单

- [x] 恢复 `dots-hyprland-desktop-rfc` 并确认其为已完成 design-only 任务。
- [x] 确认用户选择 Stage 1 only。
- [x] 物化实现任务契约。
- [x] 进入 `git-worktree-pr` envelope。
- [x] 加载或派生 `engineer` 阶段并实现变更。
- [x] 运行 `verify-change` 并写入 `docs/test-report.md`。
- [x] 运行 `review-change` 并写入 review 结论。
- [x] 生成 `report-walkthrough` 和 PR body。
- [x] 执行 `legion-wiki` 写回。
- [ ] PR merged 或明确记录 blocked/abandoned 终态，并清理 worktree、刷新主工作区。

## Handoff

- 不扩大到 RFC Stage 2；search/actions、clipboard history 和 arbitrary user commands 都不在本任务范围内。
- 不改变 Hyprland/UWSM startup ownership 或 Quickshell service target。
- Notification history 默认只存在于 Quickshell runtime memory 中。
