# Axiom Quickshell Notification Center

状态：实现已完成，PR-backed delivery 中
任务：`.legion/tasks/axiom-quickshell-notification-center/`

## 摘要

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 1，把 Axiom 当前 counter-only Quickshell notification 支持升级为 session-local notification center。实现保持现有 side dock 和 Quickshell service ownership，在 dock 旁增加 notification panel，用于查看当前会话通知历史、来源计数、unread 状态、body、actions、dismiss 和 clear flows。

## 当前有效结论

- Axiom 的第一个 end-4 风格桌面实现切片已经落在本地 Quickshell notification center，而不是导入上游 shell 或改变 session ownership。
- `quickshell.service` 仍由 `modules/desktop/quickshell.nix` 管理，并绑定 `hyprland-session.target`；Hyprland/UWSM/greetd/module 边界未改变。
- Notification history 仅保存在 Quickshell runtime/session memory 中；不要在没有 retention、clear、disable 和 privacy policy 前持久化通知内容。
- Stage 2 search/actions、clipboard history、quick controls、OSD 和 dynamic theming 仍是后续独立 milestone。

## 验证

- `git diff --cached --check`：PASS。
- Quickshell service ownership `nix eval`：PASS，`wantedBy`/`after`/`partOf` 仍为 `hyprland-session.target`。
- Axiom toplevel build：`nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` PASS。
- Scope grep：未发现 Stage 2/search/clipboard/dynamic-theme/Rofi/DMS QML surface。
- Headless/offscreen Quickshell smoke：受限于无 `PanelWindow` backend；真实通知 action/dismiss/clear 仍需 Axiom Hyprland session 手测。

## 残余风险

- 真实 notification action invocation、dismiss 和 clear behavior 尚未在 Axiom Wayland session 中端到端验证。
- 当前 grouping 是 group count，不是 collapsible grouped sections。
- 打开 panel 会将当前 unread 视为 seen；更强 inbox 语义留待后续任务。

## 相关材料

- 任务契约：`.legion/tasks/axiom-quickshell-notification-center/plan.md`
- 验证：`.legion/tasks/axiom-quickshell-notification-center/docs/test-report.md`
- Review：`.legion/tasks/axiom-quickshell-notification-center/docs/review-change.md`
- Walkthrough：`.legion/tasks/axiom-quickshell-notification-center/docs/report-walkthrough.md`
- 设计来源：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
