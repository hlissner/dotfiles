# Axiom Quickshell Notification Center

## 目标

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 1，把 Axiom 当前的 counter-only Quickshell notification 支持演进为本地 notification center：保留现有 side dock、Nix/UWSM/session 边界，同时让用户可以查看通知历史、按来源分组、执行支持的 actions、dismiss 单条通知并清空全部通知。

## 问题

当前 `config/quickshell/axiom-shell/shell.qml` 只在 `NotificationServer.onNotification` 中递增计数并显示最近摘要。用户无法从 shell 看到通知内容、历史、来源、action 或 dismiss 状态；这使 Axiom 桌面仍停留在最小通知接收层，低于 RFC 选定的 end-4 风格产品桌面目标状态。

## 验收标准

- Quickshell 仍由 `modules/desktop/quickshell.nix` 提供并作为 `quickshell.service` 绑定到 `hyprland-session.target`。
- 现有 side dock、workspace buttons、launchers、external fallback controls 和 clock 行为继续可用。
- Notification dock button 可以打开或关闭一个可见 notification panel，而不是只重置计数。
- Shell 维护当前会话内 notification history，并显示 app/source、summary、body、unread/seen 状态和 group counts。
- 用户可以 dismiss 单条通知、清空全部通知，并在通知暴露 actions 时从 panel 触发 action。
- 默认不新增持久化存储、clipboard/search/actions、dynamic theme、quick controls 或上游 installer 依赖。
- 变更有可记录验证：Nix evaluation/build 可执行；能静态检查或 smoke-check Quickshell QML；无法运行的验证需记录原因。

## 假设

- `quickshell` 的 notification service 已经足够支持当前会话内 tracked notifications、actions 和 dismiss/close 操作；若实际 API 不支持某一项，必须在实现中降级并记录。
- Axiom 第一个实现切片按 RFC review 建议仅做 Stage 1；用户已确认不合并 Stage 2。
- Notification history 本轮只保留在 Quickshell 运行时内存中，不跨 session 持久化。
- 当前视觉语言继续沿用紧凑 side dock 和深色 autumnal/Catppuccin-adjacent shell 样式。

## 约束

- 不整体导入 `end-4/dots-hyprland`、installer、generated state 或大型 shell framework。
- 不改变 Hyprland/UWSM/greetd startup path，不移动 session ownership。
- 不改变 Darwin 边界；本任务只触及 Linux/Axiom 桌面相关文件和任务文档。
- 不移除 Fuzzel、Blueman、NetworkManager editor、Pavucontrol、Wlogout 等 fallback tools。
- 不引入 notification 持久化，避免在未定义 retention/clear policy 前落盘敏感内容。

## 范围

- 重构 `config/quickshell/axiom-shell/` 中与 notification center 直接相关的 QML，允许新增小型本地 components。
- 在 side dock 上保留 notification entry，并让它控制 notification panel 的展开状态。
- 实现 notification history、basic grouping、unread count、dismiss/clear flows 和 supported action buttons。
- 仅在必要时微调 `modules/desktop/quickshell.nix` 的包/service 声明，且不得改变 service ownership。
- 写入实现、验证、review 和 walkthrough 证据。

## 非目标

- 不实现 shell-owned search/actions、clipboard history、emoji/calculator/web search。
- 不实现 quick settings、audio/network/Bluetooth inline controls 或 OSD。
- 不实现 wallpaper/theme pipeline、dynamic colors、Hyprlock theme propagation。
- 不添加 AI/cloud/OCR/translation integrations。
- 不完整重写 Axiom shell，也不支持多 shell layouts。
- 不把 notification history 持久化到磁盘。

## 设计概要

- 保持 `shell.qml` 作为 composition root，新增 focused QML components 来承载 notification data rendering 和 panel UI，避免把 shell 扩成不可维护的大文件。
- `NotificationServer` 继续作为入口；收到通知时将 notification 标记 tracked，并把它加入 session-local model。
- Dock notification button 显示 unread count 和最近状态；点击切换 panel，并在打开时可把 unread 转为 seen。
- Panel 使用 narrow side overlay/adjacent surface，与现有 dock 视觉锚点保持一致，先做稳定可用而不是追求大型控制中心。
- Actions、dismiss 和 clear 都以 Quickshell notification object 的实际能力为边界；不可用能力显示为降级 UI 或不显示。
- 回滚方式是 revert 本任务 PR，或临时恢复原 counter-only `shell.qml`。

## 风险

- Quickshell notification object API 可能与预期不同，特别是 action invocation 和 close/dismiss 方法命名。
- QML ListModel/JS object 可能不适合直接保存 complex notification objects，需要最小 wrapper 或 plain object 投影。
- Notification 内容可能包含敏感数据；本任务避免持久化，但 panel 可见性和 clear 行为必须清晰。
- 过度组件化会把小型 shell 变成框架；本任务只允许与 notification center 直接相关的拆分。
- 无法在 CI 中完整模拟桌面通知 actions 时，需要把 runtime validation 留给 Axiom session，并记录缺口。

## 阶段

- Contract：物化本 Stage 1 实现任务，确认范围和非目标。
- Engineer：在隔离 git worktree 中实现 Quickshell notification center。
- Verify：运行 Nix/QML/静态或可用 smoke 验证，并记录 test report。
- Review：执行实现 readiness review，必要时回到 Engineer。
- Walkthrough：生成面向评审者的变更走读和 PR body。
- Wiki：写回 Legion wiki 的任务总结与当前有效结论。

## 来源

- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC 评审：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- Wiki 结论：`.legion/wiki/tasks/dots-hyprland-desktop-rfc.md`
- 当前 shell：`config/quickshell/axiom-shell/shell.qml`
- Service owner：`modules/desktop/quickshell.nix`
