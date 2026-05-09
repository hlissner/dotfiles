# RFC：让 Axiom 演进到 end-4 风格的 Hyprland 产品桌面

> 状态：已评审，PASS，可用于未来实现规划
> 类型：RFC Heavy，design-only
> 创建时间：2026-05-09
> 任务：`.legion/tasks/dots-hyprland-desktop-rfc/`

## 执行摘要

当前 Axiom 已经具备正确的架构主线：NixOS、Hyprland、UWSM、portals、greetd、仓库自有 Quickshell、Zen、Vesktop、Steam、Thunar、fcitx5，以及可见 side dock。`end-4/dots-hyprland` 展示了下一层成熟度：把 Quickshell 做成完整桌面环境，包含 notification center、action/search surface、quick settings、OSD、dynamic wallpaper/theme pipeline、lock/session UI、clipboard history 和 rich capture workflows。

决策：Axiom 应向 `end-4/dots-hyprland` 的能力等价演进，但保留 Axiom 的 Nix-native 架构、UWSM/session ownership、host/module 边界和紧凑可评审实现。不要整体导入上游。

## 目标

- 定义 Axiom 应从 `end-4/dots-hyprland` 参考中获得的目标桌面能力。
- 保留当前 Axiom 强于上游的决策：Nix ownership、UWSM、systemd user service、declarative monitors 和 scoped host modules。
- 优先选择增量 Quickshell service growth，而不是用大型上游 framework 替换 Axiom 本地 shell。
- 在设计中保留 Isabel 的工作站经验：可靠性、app defaults、media/browser/chat/gaming polish、Bluetooth/Wi-Fi 质量，以及 coherent theme/MIME/font coverage。
- 提供带验证与回滚边界的分阶段未来实现路径。

## 非目标

- 本任务不实现改动。
- 不整体导入 `end-4/dots-hyprland` 文件、installer、Quickshell tree 或 package lists。
- 不用上游 session 假设替换 UWSM。
- 不在没有单独决策的情况下引入 broad KDE/Plasma dependencies。
- 不在没有 privacy 和 secrets policy 的情况下加入 AI/cloud/booru/wallpaper automation。
- 第一个实现 pass 不尝试让 Axiom 支持多 shell families。

## 目标状态

Axiom 应成为 Nix-native Hyprland 产品桌面，由 Quickshell 拥有日常可见交互：

- persistent side dock 继续作为主要视觉锚点；
- notification center 支持 history、grouping、actions、unread state 和 clear/dismiss flows；
- shell-owned search 支持 apps、actions、web、calculator、clipboard、emoji 和 user-defined commands，并以 Fuzzel 作为 fallback；
- quick controls 暴露 audio devices/streams、network、Bluetooth、media、power/session 和 basic settings；
- Quickshell OSD 处理 volume/brightness/media feedback，并可与现有 `hey .osd` scripts 互操作；
- wallpaper/theme handling 可选地把颜色传播到 shell、Hyprland、lock screen、launcher、GTK/Qt 和 terminal surfaces；
- guide/cheatsheet/onboarding 从 shell 中可用，而不仅是 markdown 文件；
- screenshot/recording 保持稳定，OCR/translation/clipboard-history enhancements 作为后续可选项；
- 当前 Axiom workstation apps 和 hardware concerns 继续是一等公民。

## 设计原则

- 功能等价优先于代码等价：复制用户价值，而不是复制上游文件布局。
- Nix 拥有安装；Quickshell 只能在 state 边界清晰后拥有交互状态。
- 现有外部工具在 shell-native controls 可靠前继续作为 fallback。
- 优先使用小型可组合 QML/services，而不是导入大型 opaque shell。
- Axiom 当前 side dock 是优势；先把它扩展成 control surface，再考虑 alternate families。
- 每个阶段都必须能通过禁用 module/service 或 revert PR 回滚。

## 备选方案

### 方案 A：整体导入 end-4/dots-hyprland

- 优点：最快获得表面功能广度。
- 缺点：大型 mutable installer model、非 Nix package assumptions、UWSM 冲突、广泛依赖、generated user state、AI/cloud scope、难以评审。
- 决策：拒绝。

### 方案 B：保持当前 Axiom shell 不变

- 优点：风险最低，且已经可构建。
- 缺点：Axiom 会明显落后于目标产品：没有 notification center、action search、inline controls、OSD、dynamic theming、clipboard history 或 shell settings。
- 决策：不作为最终状态；只可作为回滚状态。

### 方案 C：增量构建 Axiom-native 能力等价

- 优点：保留 Nix/UWSM/module 边界，让 Axiom 保留 side dock，允许分阶段验证，并且只导入已证明有价值的产品思路。
- 缺点：比整体导入更慢，需要谨慎设计 Quickshell service。
- 决策：选择。

### 方案 D：切到 KDE/Plasma-heavy control layer

- 优点：Network、Bluetooth、system settings 和 portal UX 的控制面板成熟。
- 缺点：依赖重力大；除非 Axiom 明确选择 KDE 作为 control substrate，否则会与产品视觉/架构不匹配。
- 决策：延后。只有在明确选择后，外部 KDE 工具才可作为 optional fallback。

## 分阶段演进计划

### Stage 1：Shell State 与 Notification Center

范围：

- 在不改变可见 side-dock 概念的前提下，把 Axiom 紧凑 `shell.qml` 拆成小型本地 components/services。
- 添加 notification history、按 app grouping、actions、unread count、clear/dismiss flows 和可见 notification panel。
- 保留当前 `NotificationServer` 行为作为最小 fallback。

验收：

- Quickshell 仍作为 `quickshell.service` 在 `hyprland-session.target` 下启动。
- Notifications 可以接收、列出、在支持时执行 action、dismiss 和 clear。
- 现有 dock launchers 和 controls 仍可工作。

回滚：

- 禁用新的 notification panel/service，回到当前 counter-only shell。

### Stage 2：Shell-Owned Search 与 Actions

范围：

- 添加 Quickshell search/launcher panel，支持 apps、configured actions、web search、calculator、clipboard history 和 emoji。
- 在 shell search 验证前，保留 `fuzzel` 作为 `Super+Space` 或 secondary binding 的 fallback。
- 在仓库自有、可评审位置添加 user-action configuration。
- 默认禁用任意脚本执行；在单独策略存在前只允许已评审的本地 actions。
- 持久 clipboard history 在 retention、clear behavior 和 disable switches 明确前保持 opt-in。

验收：

- App launch 和常用 actions 不再依赖 Rofi。
- Search 失败时可以 fallback 到 Fuzzel 或 direct commands。
- 不需要 mutable downloaded scripts。

回滚：

- 把 `Super+Space` 和 dock `APP` 恢复为只打开 `fuzzel`。

### Stage 3：Quick Controls 与 OSD

范围：

- 添加 shell panels 或 popovers，用于 audio output/input、network status、Bluetooth status、media controls、lock/session/power 和 basic desktop settings。
- 可行时使用 shell-native services；保留 `nm-connection-editor`、`blueman-manager`、`pavucontrol` 和 `wlogout` 作为明确 fallback buttons。
- 将现有 `hey .osd` volume/brightness feedback 集成进或替换为 Quickshell OSD。

验收：

- 用户可以从可见 shell 查看和控制常见桌面状态。
- 外部 fallback 工具仍可访问。
- Media keys 和现有 Hyprland bindings 继续工作。

回滚：

- 禁用 quick-control popovers，并把 dock buttons 恢复为外部工具。

### Stage 4：Wallpaper 与 Theme Pipeline

范围：

- 决定 dynamic colors 是 Axiom 核心能力还是 optional theme mode。
- 如果采用，使用受控 Matugen-style pipeline，只向声明过的 cache/config targets 写 generated files。
- 只有在每个 target 有明确 owner 后，才把颜色传播到 Quickshell、Hyprland、Hyprlock、launcher、GTK/Qt 和 terminal。

验收：

- Theme generation 足够可复现、可调试。
- Static autumnal theme 仍可作为 fallback。
- Generated state boundaries 已记录。

回滚：

- 禁用 dynamic theme generation，回到 static autumnal assets。

### Stage 5：Power-User Extensions

范围：

- 在 core shell features 稳定后，才添加 clipboard history UI、OCR、screen translation、更丰富 recording workflows、Google Lens-like actions 或 AI sidebars。
- AI/cloud features 必须作为独立 RFC/security review 项目处理。

验收：

- Extensions 是 optional、locally controllable，且不削弱桌面基线。
- Privacy-sensitive features 有 gate 和文档。

回滚：

- 各 extension module 可独立禁用。

## 未来实现边界

- 保持 `modules/desktop/quickshell.nix` 作为 service/package owner。
- 保持 `config/quickshell/axiom-shell/` 作为仓库自有 shell source。
- 保持 `modules/desktop/hyprland.nix` 作为 session、portal、monitor generation 和 Hyprland pre/post config owner。
- 不添加上游 installer scripts 或 distro package managers。
- 不让 shell state 成为 host/session configuration 的隐藏真源。
- 在等价 shell 功能验证前，不移除 Axiom 的外部 fallback tools。

## 未来实现验证策略

- 构建 Axiom：`nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`。
- 评估 Quickshell service ownership、linked config path、expected packages 和 `hyprland-session.target` dependency。
- 在 package environment 支持时运行 Quickshell syntax/runtime smoke checks。
- 任何 binding/rule/session 改动后，用 `Hyprland --verify-config` 验证生成 Hyprland config。
- 在 Axiom 硬件上演练 notification receipt/actions、launcher/search、quick controls、OSD、screenshots、lock、media keys 和 fallback external tools。
- 回归搜索：避免 Rofi/DMS primary-shell 重新进入，避免 mutable upstream installer artifacts 进入仓库。
- 对 dynamic theming，验证 generated files、ownership、回滚到 static theme，以及不会向 repository-managed paths 做 uncontrolled writes。

## 回滚策略

- Merge 前：revert 未来实现 PR，或 revert 引入失败 subsystem 的 stage commit。
- 部署后：boot/switch 到上一代 NixOS generation。
- 如果只有 Quickshell 失败：stop/disable `quickshell.service`，临时依赖 Hyprland keybindings 和外部 fallback tools。
- 如果 dynamic theming 失败：禁用 generated theme mode，恢复 static autumnal theme。
- 避免数据迁移；shell cache/state directories 可保留，除非它们导致反复启动失败。

## 安全与隐私

- Core shell features 不应引入 secrets。
- Search/actions 默认不得执行 remote 或 downloaded scripts。
- AI/cloud/OCR translation integrations 需要单独 opt-in design，覆盖 network behavior、credentials、logging 和 failure modes。
- Notification 和 clipboard history 可能暴露敏感数据；实现前必须明确 storage、retention、clear controls 和 disable switches。

## 未决问题

- Dynamic Material theming 应成为 Axiom 身份的一部分，还是保持为 autumnal theme 之上的 optional mode？
- Axiom 的 inline Wi-Fi/Bluetooth/audio 应优先使用什么 control backend：shell-native DBus/service integrations、GTK tools，还是 KDE tooling？
- Axiom 将来应支持多 shell layouts，还是坚持一个强 side-dock 产品方向？
- Clipboard history 应保存多少，是否跨 session 持久化？

## 决策

未来实现任务采用方案 C：Axiom-native 增量能力等价。第一个实现任务应只做 Stage 1，除非用户明确合并 Stage 1 和 Stage 2。Stage 2-5 应保持为独立 milestone，因为它们会增加 dependency、state 和 privacy surface area。

## 参考

- 任务契约：`.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- 研究：`.legion/tasks/dots-hyprland-desktop-rfc/docs/research.md`
- llm-wiki：`.legion/tasks/dots-hyprland-desktop-rfc/docs/llm-wiki-dots-hyprland.md`
- 对比：`.legion/tasks/dots-hyprland-desktop-rfc/docs/comparison.md`
- 当前 Axiom host：`hosts/axiom/default.nix`
- 当前 Axiom shell：`config/quickshell/axiom-shell/shell.qml`
- 当前 Axiom Hyprland config：`config/hypr/hyprland.conf`
- Isabel 研究：`isa.md`
