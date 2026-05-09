# Axiom Quickshell Quick Controls and OSD

## 任务标识

- **name**: Axiom Quickshell Quick Controls and OSD
- **taskId**: `axiom-quickshell-quick-controls-osd`
- **parent design**: `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md` Stage 3

## 目标

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 3，把 Axiom 从外部工具按钮集合推进到 Quickshell-owned quick controls 和 OSD。目标是让用户可以从可见 shell 查看和触发 audio、network、Bluetooth、media、lock/session/power 与基础桌面动作，并让 volume/brightness/media feedback 进入 Quickshell OSD，同时保留现有 external fallback tools 和 media keys。

## 问题陈述

Stage 1/2 已让 Axiom 拥有 notification center 和 shell-owned search/actions，但 dock 底部的 `WIFI`、`BT`、`VOL`、`PWR` 仍只是直接打开外部工具，media key feedback 仍走 `hey .osd` / `notify-send` 风格。Axiom 还缺少一个可见、统一、可扩展的 quick-control surface 来承载常见桌面状态和 controls，因此仍低于父 RFC 选定的 end-4 风格产品桌面目标。

## 验收标准

- [ ] Quickshell 仍由 `modules/desktop/quickshell.nix` 提供，并作为 `quickshell.service` 绑定到 `hyprland-session.target`。
- [ ] 现有 side dock、workspace buttons、Stage 1 notification panel、Stage 2 search panel、clock 和 launcher/search fallback 行为继续可用。
- [ ] Dock 的 network、Bluetooth、audio、power/session/media 入口优先打开 Quickshell quick-controls panel 或 popover，而不是只直接启动外部工具。
- [ ] Quick controls 显示至少 audio output/input 状态或 controls、network status/fallback、Bluetooth status/fallback、media playback controls、lock/session/power actions 和基础 desktop settings/action buttons。
- [ ] `nm-connection-editor`、`blueman-manager`、`pavucontrol`、`wlogout`、`playerctl` 或 direct commands 仍作为明确 fallback 可访问。
- [ ] Volume/brightness/media key feedback 进入 Quickshell OSD 或通过兼容 wrapper 优先通知 Quickshell OSD；现有 media keys 和 Hyprland bindings 继续工作。
- [ ] 不引入 Stage 4 dynamic theming、wallpaper pipeline、AI/cloud/OCR/translation 或 large upstream shell framework。
- [ ] 变更有可记录验证：Nix evaluation/build、Hyprland config verification、helper/static smoke、scope grep；无法运行的 live Quickshell/layer-shell 验证需记录原因。

## 假设 / 约束 / 风险

- **假设**: Stage 1 notification center 和 Stage 2 search/actions 是当前基线，必须保留而不是重写。
- **假设**: Stage 3 可以先实现 shell-visible status + fallback buttons + common command controls；完整 device enumeration 和 deep DBus management 可作为后续增强。
- **假设**: Axiom 当前 media keys already work through Hyprland bindings and `hey .osd`; this task may route those bindings through a Quickshell-aware helper but must keep the underlying commands available.
- **约束**: 不整体导入 `end-4/dots-hyprland`、installer、generated state 或大型 shell framework。
- **约束**: 不改变 Hyprland/UWSM/greetd startup ownership，不移动 Quickshell service owner。
- **约束**: 不改变 Darwin 边界；本任务只触及 Linux/Axiom desktop files and task/wiki docs。
- **约束**: External fallback tools remain available until shell-native controls are validated in a real Axiom session。
- **约束**: Quick-control actions must be reviewed local commands/fixed helper verbs; no remote scripts or unbounded arbitrary command execution。
- **风险**: Audio/network/Bluetooth shell-native state may require DBus/service APIs that are not feasible to fully validate headlessly; the first implementation may need helper-backed status and explicit fallbacks。
- **风险**: OSD replacement can regress media-key feedback if IPC/session focus fails; fallback behavior must be documented and verified where possible。
- **风险**: More panels can destabilize Quickshell `Variants` composition; each new panel/window must keep the one `PanelWindow` per `Variants` pattern。

## 要点

- **Stage 3 only**: deliver quick controls and OSD without pulling in theme/wallpaper or power-user extensions。
- **Fallback-first controls**: shell-native status/control is primary, but external tools remain visible and callable。
- **Axiom-native ownership**: Nix owns packages/helpers/services, Quickshell owns UI/OSD, Hyprland owns only keybindings and fallback wiring。
- **Incremental DBus depth**: prefer reliable helper-backed state and actions over attempting a broad DBus control center in one pass。

## 范围

- `config/quickshell/axiom-shell/` - 新增或调整 quick controls panel/popovers、OSD component、control/status models and command wiring。
- `config/quickshell/axiom-shell/search/` or nearby helper location - extend or add small fixed-verb helper(s) for status/actions/OSD if needed。
- `modules/desktop/quickshell.nix` - add packages/options/services needed for quick controls/OSD while preserving service ownership。
- `config/hypr/hyprland.conf` and if necessary `config/hypr/bin/osd*.zsh` - minimal binding/wrapper changes to route volume/brightness/media feedback to Quickshell OSD while preserving fallback behavior。
- `.legion/tasks/axiom-quickshell-quick-controls-osd/docs/` - design, review, verification, walkthrough and PR evidence。
- `.legion/wiki/**` - closing writeback with Stage 3 current decisions and reusable patterns。

## 非目标

- 不实现 Stage 4 wallpaper/theme pipeline、dynamic colors、Matugen propagation or Hyprlock/theme propagation。
- 不实现 Stage 5 AI/cloud/OCR/screen translation/power-user capture workflows。
- 不完整重写 Axiom shell，不支持 multiple shell families/layouts。
- 不移除 `nm-connection-editor`、`blueman-manager`、`pavucontrol`、`wlogout`、Fuzzel 或 direct media-key commands。
- 不承诺完整 Wi-Fi/Bluetooth/audio device management parity with desktop settings apps in the first pass。
- 不改变 existing UWSM/greetd/session startup model or Darwin imports。

## 设计索引

> **Design Source of Truth**: 本任务必须先产出 task-local RFC：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/rfc.md`。父级方向来自 `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md` Stage 3。

**摘要**:
- 核心流程: dock control buttons open a Quickshell quick-controls panel; panel shows status/action sections for audio, network, Bluetooth, media and session controls; media/brightness/volume key paths emit Quickshell OSD events with command fallback。
- 验证策略: Nix parse/eval/build, helper smoke, Hyprland config verification, scope grep, and live-session checklist for Quickshell panel/OSD behavior that cannot run headlessly。

## 设计概要

- 保持 `shell.qml` as composition root, adding focused QML components for quick controls and OSD instead of turning the root into a control-center monolith。
- Quick controls should use fixed local commands and helper status snapshots first: `pamixer`/PipeWire audio state, `playerctl` media, NetworkManager/Bluetooth status via available CLI/DBus-safe tools, and fallback buttons for full settings apps。
- OSD should expose a Quickshell IPC target or helper-compatible path so Hyprland media keys can show volume/brightness/media feedback through shell UI while still applying the underlying state change。
- Panels must follow the established separate `Variants` / `PanelWindow` pattern to avoid the prior side-dock regression。
- Rollback is restoring dock controls and media keys to existing external commands / `hey .osd` behavior, or reverting the implementation PR。

## 阶段概览

1. **Contract** - 物化 Stage 3 implementation task and confirm boundaries/non-goals。
2. **RFC** - Define quick-control sections, helpers, IPC/OSD path, fallback and verification strategy。
3. **Review RFC** - Review design for hidden DBus/OSD/fallback complexity before coding。
4. **Engineer** - Implement in isolated `git-worktree-pr` worktree。
5. **Verify** - Run Nix/helper/static/Hyprland validation and record runtime gaps。
6. **Review** - Execute readiness review, with special attention to fallback and session regression risks。
7. **Walkthrough** - Generate reviewer-facing report and PR body。
8. **Wiki** - Write back task summary, decisions and patterns。
9. **PR Lifecycle** - Commit, rebase, push, open PR, attempt auto-merge, follow checks/review, cleanup and refresh main workspace。

## 来源

- Parent RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- Stage 2 summary：`.legion/wiki/tasks/axiom-quickshell-search-actions.md`
- Current shell：`config/quickshell/axiom-shell/shell.qml`
- Current search/actions：`config/quickshell/axiom-shell/SearchPanel.qml`
- Current OSD script：`config/hypr/bin/osd.zsh` and `config/hypr/bin/osd.d/*.zsh`
- Current media key bindings：`config/hypr/hyprland.conf`
- Service owner：`modules/desktop/quickshell.nix`

---
*Created: 2026-05-09 | Updated: 2026-05-09*
