# Axiom Quickshell Side Dock Regression

## 目标

修复 PR #14 后 Axiom 左侧 side dock 不显示的回归，恢复原有 dock 可见性，同时保留新加入的 session-local notification center。

## 问题

PR #14 在 `config/quickshell/axiom-shell/shell.qml` 的同一个 `Variants` 中放入了两个 sibling `PanelWindow`：原 side dock 和新的 notification panel。Quickshell `Variants` 语义更适合一个 delegate/component；多个 sibling delegate 可能导致只有一个 panel 被实例化或可见，从而让 side dock 消失。

## 验收标准

- Quickshell 启动后左侧 side dock 仍是默认可见的 persistent panel。
- Notification panel 仍可由 dock notification button 控制显示/隐藏。
- 不改变 `quickshell.service`、`hyprland-session.target`、Hyprland/UWSM/greetd/session ownership。
- 不扩大到 notification center 功能重写、search/actions、clipboard history、quick controls、OSD 或 dynamic theming。
- Axiom NixOS toplevel build 通过；能记录 Quickshell headless/offscreen smoke 的结果或环境限制。

## 假设

- 回归根因是 `Variants` 下多个 `PanelWindow` sibling 的结构问题，而不是 systemd service、Hyprland session 或 package ownership 问题。
- 最小正确修复是让 dock 和 notification panel 分别有各自的 screen variants/delegate，而不是把两个 `PanelWindow` 放在同一个 `Variants` delegate position。
- 当前 notification center 的数据 model 和 action/dismiss/clear 逻辑保持不变。

## 约束

- 不 revert 整个 notification center，除非最小结构修复无法恢复 dock。
- 不修改 host、Hyprland、Quickshell service module 或 package list。
- 不触碰 Darwin 边界。
- 不删除 PR #14 的 Legion evidence；本任务只补回归修复证据。

## 范围

- 修改 `config/quickshell/axiom-shell/shell.qml` 的 Quickshell window composition structure。
- 必要时更新任务文档、验证报告、review、walkthrough 和 wiki。

## 非目标

- 不改变 notification panel visual design 或功能范围。
- 不实现更复杂的 grouping/inbox semantics。
- 不添加 runtime persistence 或外部 notification daemon。
- 不处理 unrelated Nix evaluation warnings。

## 设计概要

- 保留原 side dock `PanelWindow` 作为第一个 `Variants` 的唯一 delegate。
- 把 notification panel 移到第二个 `Variants`，同样按 `Quickshell.screens` 创建独立 `PanelWindow`。
- 继续共享 `root.notificationPanelOpen`、`NotificationServer` 和 `NotificationPanel` component。
- 用 Nix build/eval 证明 service/session 边界未漂移；用 headless smoke 记录是否仍受 `PanelWindow` backend 限制。

## 风险

- 无真实 Wayland layer-shell 环境时，无法在 CI/headless 中完整证明 panel 可见性。
- 如果 Quickshell 对多个 `Variants` 也有其他约束，需要进一步降级为手写 screen-specific composition。
- 修复必须避免再次破坏 notification panel toggle。

## 阶段

- Contract：物化 side dock regression 修复合同。
- Engineer：在隔离 worktree 中最小修改 QML structure。
- Verify：运行 Nix build/eval、diff hygiene 和可用 Quickshell smoke，并记录 test report。
- Review：只读审查是否恢复 dock 且未扩大 scope。
- Walkthrough：生成 reviewer-facing 摘要和 PR body。
- Wiki：写回回归结论和 Quickshell `Variants` 结构模式。
