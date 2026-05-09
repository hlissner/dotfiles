# Axiom Quickshell Search and Actions - 任务清单

## 快速恢复

**当前阶段**: PR lifecycle
**当前检查项**: commit/rebase/push/create PR
**进度**: Legion implementation chain complete; PR lifecycle pending

---

## 状态

- 执行模式：待 `legion-workflow` 在 contract 稳定后选择；预计为中风险默认实现模式。
- 范围：`dots-hyprland-desktop-rfc` Stage 2 only；实现 shell-owned search/actions。
- 风险边界：用户选择功能完整优先；clipboard history 可持久化，但必须有 clear/disable 和回滚路径。

## 阶段 1: Contract ✅ COMPLETE

- [x] 恢复父 RFC 和 Stage 1 任务状态 | 验收: 已确认 Stage 1 notification center 为当前基线
- [x] 向用户确认 Stage 2 clipboard/privacy 偏好 | 验收: 用户选择功能完整优先
- [x] 回读 `plan.md` 和 `tasks.md` | 验收: contract 字段完整且不是摘要骨架

## 阶段 2: RFC ✅ COMPLETE

- [x] 写入 task-local RFC | 验收: 覆盖 providers、actions config、clipboard、fallback、verification 和 rollback
- [x] 更新任务日志 | 验收: 记录关键设计决策和下一步

## 阶段 3: Review RFC ✅ COMPLETE

- [x] 执行 `review-rfc` | 验收: RFC PASS 或修复后 PASS

## 阶段 4: Engineer ✅ COMPLETE

- [x] 进入 `git-worktree-pr` envelope | 验收: 修改在隔离 worktree 中进行
- [x] 实现 Quickshell search/actions Stage 2 | 验收: 满足 `plan.md` 验收标准

## 阶段 5: Verify ✅ COMPLETE

- [x] 执行 `verify-change` | 验收: `docs/test-report.md` 记录可信验证证据

## 阶段 6: Review Change ✅ COMPLETE

- [x] 执行 `review-change` | 验收: readiness review PASS 或返回 Engineer/RFC

## 阶段 7: Walkthrough ✅ COMPLETE

- [x] 执行 `report-walkthrough` | 验收: `docs/report-walkthrough.md` 和 `docs/pr-body.md` 可供评审

## 阶段 8: Wiki ✅ COMPLETE

- [x] 执行 `legion-wiki` 写回 | 验收: wiki 记录 Stage 2 当前结论、风险和复用模式

## PR Lifecycle 🟡 IN PROGRESS

- [ ] Commit scope changes | 验收: branch has a reviewable commit ← CURRENT
- [ ] Rebase branch on latest `origin/master` before push | 验收: branch is current with base
- [ ] Push PR branch | 验收: remote branch exists
- [ ] Create or update PR | 验收: PR body links/summarizes Legion evidence
- [ ] Attempt auto-merge and follow checks/review | 验收: required checks/review handled or blocker recorded
- [ ] Cleanup worktree and refresh main workspace after terminal PR state | 验收: worktree removed and main baseline refreshed
