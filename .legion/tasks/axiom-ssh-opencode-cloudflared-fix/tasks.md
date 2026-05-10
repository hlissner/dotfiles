# Axiom SSH Autossh and Opencode Cloudflared Fix - 任务清单

## 快速恢复

**当前阶段**: 阶段 5 - Delivery
**当前检查项**: 完成 review、walkthrough、wiki writeback 与 PR 生命周期
**进度**: 4/5 任务完成
---

## 阶段 1: Contract ✅ COMPLETE

- [x] 创建稳定 Legion 任务契约 | 验收: plan.md 和 tasks.md 明确目标、scope、验收、风险与阶段
---

## 阶段 2: Design ✅ COMPLETE

- [x] 形成 SSH/autossh/opencode/cloudflared design-lite/RFC | 验收: 设计覆盖端口、secret、systemd、rollback 与验证边界
---

## 阶段 3: Implementation ✅ COMPLETE

- [x] 实现 bounded dotfiles 变更并生成 cloudflared secret | 验收: 变更限于授权 scope 且不包含明文 secret
---

## 阶段 4: Verification ✅ COMPLETE

- [x] 运行 targeted eval/build 与可行的 cloudflared/ssh 检查 | 验收: 证据写入 docs/test-report.md，无法验证项显式记录
---

## 阶段 5: Delivery ⏳ NOT STARTED

- [ ] 完成 review、walkthrough、wiki writeback 与 PR 生命周期 | 验收: review/report/wiki/PR 证据齐全或 blocker 明确 ← CURRENT
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-05-10 12:49*
