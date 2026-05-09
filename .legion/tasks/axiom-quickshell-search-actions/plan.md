# Axiom Quickshell Search and Actions

## 任务标识

- **name**: Axiom Quickshell Search and Actions
- **taskId**: `axiom-quickshell-search-actions`
- **parent design**: `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md` Stage 2

## 目标

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 2，把 Axiom 的 launcher 入口从只打开 Fuzzel 演进为 Quickshell-owned search/action surface。目标是让用户可从 shell 搜索和启动 apps、运行已配置本地 actions、发起 web search、计算表达式、选择 emoji，并使用 clipboard history，同时保留 Fuzzel 作为回滚和失败 fallback。

## 问题陈述

当前 Axiom 已完成 Stage 1 notification center，但 `APP` dock button 和 launcher 路径仍主要依赖 `fuzzel`。这让 Quickshell 还不是完整桌面产品入口：常用 actions、calculator、emoji、web search 和 clipboard history 分散在外部工具或旧 Rofi 习惯中，无法形成一个可评审、可扩展的 Axiom-native interaction model。

## 验收标准

- [ ] Quickshell 仍由 `modules/desktop/quickshell.nix` 提供，并作为 `quickshell.service` 绑定到 `hyprland-session.target`。
- [ ] 现有 side dock、workspace buttons、Stage 1 notification panel、external fallback controls 和 clock 行为继续可用。
- [ ] `APP` dock button 打开 Quickshell search panel；`Super+Space` 或等价 primary launcher binding 优先打开该 panel，并保留 Fuzzel fallback。
- [ ] Search panel 能搜索和启动 desktop apps，不再依赖 Rofi 作为 app launch primary path。
- [ ] Search panel 能运行仓库内声明的 local actions，包括至少 guide、terminal、files、browser/web search、power/fallback launcher 类常用动作。
- [ ] Calculator、emoji 和 clipboard history 可以从同一个 search surface 使用；clipboard history 按用户偏好以功能完整为先，可跨 session 持久化，但必须提供清空与禁用路径。
- [ ] 不引入 upstream installer、downloaded scripts、DMS/Rofi primary shell 或未声明的外部配置真源。
- [ ] 变更有可记录验证：Nix evaluation/build 可执行；能静态检查或 smoke-check Quickshell QML；无法运行的 runtime 验证需记录原因。

## 假设 / 约束 / 风险

- **假设**: Stage 1 notification center 是当前基线，且应被保留而不是重写。
- **假设**: 用户明确选择功能完整性优先于严格隐私最小化；本任务允许 clipboard history 持久化，但必须暴露 clear 和 disable 行为。
- **假设**: Axiom 是单用户本机桌面，search/actions 默认服务本地交互，不设计为多用户或远程控制 surface。
- **约束**: 不整体导入 `end-4/dots-hyprland`、installer、generated state 或大型 shell framework。
- **约束**: 不改变 Hyprland/UWSM/greetd startup ownership，不移动 Quickshell service owner。
- **约束**: 不改变 Darwin 边界；本任务只触及 Linux/Axiom 桌面相关文件和任务文档。
- **约束**: Fuzzel 必须作为 fallback 保留，直到 shell search 在真实 session 中验证可靠。
- **约束**: Local actions 必须来自仓库声明配置；不执行远程下载脚本，不把任意用户输入直接当 shell script 执行。
- **风险**: Clipboard history 可能保存敏感内容；本任务接受单用户本机风险，但必须提供清空、禁用和回滚路径。
- **风险**: Quickshell app discovery、clipboard watcher 或 process integration 的 API/behavior 可能与预期不同，可能需要降级为 external helper-backed implementation。
- **风险**: Search panel 容易扩成大型 framework；本任务应保持小型、可评审组件，而不是复刻 end-4 shell。
- **风险**: Launcher binding 和 panel focus 行为需要真实 Axiom Hyprland session 才能完整验证。

## 要点

- **功能完整优先**: Stage 2 一次交付 app/action/web/calculator/emoji/clipboard 六类 search 能力，而不是只做 app launcher。
- **Axiom-native ownership**: Nix 管安装和 packages，Quickshell 管可见 interaction surface，Hyprland 只负责 binding/fallback wiring。
- **Fallback-first rollout**: Shell search 成为 primary path，但 Fuzzel/direct commands 继续存在，便于失败回滚。
- **声明式 actions**: Actions 应放在仓库自有、可评审位置，后续可以扩展，但本轮不允许 remote/mutable script source。

## 范围

- `config/quickshell/axiom-shell/` - 新增或调整 search panel、action model、clipboard/emoji/calculator/app launch UI 相关 QML。
- `modules/desktop/quickshell.nix` - 补齐 search/action/clipboard/emoji/calculator 所需 packages、service 或 environment，且保持 service ownership 不变。
- `config/hypr/` 或 `modules/desktop/hyprland.nix` - 仅在需要 launcher binding/fallback wiring 时做最小改动。
- `.legion/tasks/axiom-quickshell-search-actions/docs/` - 写入 task-local RFC、review、verification、walkthrough 和 PR body 证据。
- `.legion/wiki/**` - 收口时写回 Stage 2 当前有效结论和可复用模式。

## 非目标

- 不实现 Stage 3 quick controls、audio/network/Bluetooth inline control 或 OSD。
- 不实现 Stage 4 wallpaper/theme pipeline、dynamic colors 或 Hyprlock/theme propagation。
- 不实现 Stage 5 AI/cloud/OCR/screen translation/power-user capture workflows。
- 不完整重写 Axiom shell，不支持多 shell families/layouts。
- 不移除 Fuzzel fallback，不把 Rofi/DMS 重新设为 primary shell path。
- 不解决所有 desktop-entry edge cases；只要求常用 GUI apps 和声明 actions 可靠。

## 设计索引

> **Design Source of Truth**: 本任务必须先产出 task-local RFC：`.legion/tasks/axiom-quickshell-search-actions/docs/rfc.md`。父级方向来自 `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md` Stage 2。

**摘要**:
- 核心流程: dock/binding 打开 Quickshell search panel，panel 聚合 apps、declared actions、web/calculator/emoji/clipboard providers，并通过 explicit launch/copy/action flows 执行。
- 验证策略: Nix evaluation/build、scope grep、QML/static smoke、Hyprland config verification；真实 Axiom session 需验证 panel focus、app launch、clipboard clear/disable、emoji copy 和 fallback behavior。

## 设计概要

- 保持 `shell.qml` 作为 composition root，但把 search panel 拆成 focused local components，避免再次扩大单文件复杂度。
- App search 优先使用可声明或可查询的 desktop entries；如果 Quickshell API 不足，允许用本地 helper/provider 生成可搜索 app list。
- Actions 采用仓库内静态 allowlist，覆盖 guide、terminal、files、browser/web search、power/fallback launcher 等常用动作。
- Calculator 和 emoji 应优先使用本地离线工具或轻量 shell-side logic；不引入网络依赖。
- Clipboard history 允许持久化以满足用户功能完整偏好，但实现必须包含 clear all 和 disable switch/path，并记录敏感数据风险。
- 回滚方式是 revert 本任务 PR，或把 launcher binding 和 `APP` dock button 恢复到只打开 Fuzzel。

## 阶段概览

1. **Contract** - 物化本 Stage 2 实现任务，确认功能完整优先、scope、non-goals 和风险边界。
2. **RFC** - 产出 task-local RFC，明确 providers、packages、actions config、clipboard retention/clear/disable 和 fallback wiring。
3. **Review RFC** - 对 search/actions/clipboard 设计进行对抗审查，PASS 后才能编码。
4. **Engineer** - 在隔离 git worktree 中实现 Quickshell search/actions Stage 2。
5. **Verify** - 运行 Nix/QML/static/runtime 可用验证，并记录 test report。
6. **Review** - 执行 readiness review；若发现设计/实现不一致则回到 RFC 或 Engineer。
7. **Walkthrough** - 生成面向评审者的变更走读和 PR body。
8. **Wiki** - 写回 Legion wiki 的任务总结、当前决策和复用模式。

## 来源

- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- Stage 1 任务：`.legion/tasks/axiom-quickshell-notification-center/plan.md`
- Stage 1 回归修复：`.legion/tasks/axiom-quickshell-side-dock-regression/plan.md`
- Wiki 结论：`.legion/wiki/tasks/dots-hyprland-desktop-rfc.md`
- 当前 shell：`config/quickshell/axiom-shell/shell.qml`
- Service owner：`modules/desktop/quickshell.nix`

---
*Created: 2026-05-09 | Updated: 2026-05-09*
