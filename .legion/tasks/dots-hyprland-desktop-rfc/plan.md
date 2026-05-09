# Dots Hyprland 桌面 RFC

## 目标

研究 `end-4/dots-hyprland`，把它的桌面环境配置整理成一份本地 llm-wiki 风格参考；再把该目标状态与 Isabel、当前 Axiom 桌面做对比；最后产出一份 RFC，说明 Axiom 如何从当前状态演进到该目标状态。

## 问题

Axiom 已经朝 Hyprland + Quickshell 产品桌面演进，但下一阶段目标还没有被清晰定义。`end-4/dots-hyprland` 代表了更完整、更集成的 Hyprland 桌面产品形态，包含丰富 shell、主题、控制面板和服务层。进入实现前，仓库需要一份可评审的设计产物，用来说明哪些能力值得吸收、哪些点会与现有 Axiom/Isabel 决策冲突，以及什么迁移路径更安全。

## 验收标准

- 任务内 llm-wiki 文档总结 `end-4/dots-hyprland` 的相关桌面配置、架构、功能面、依赖、运行时假设和采用建议。
- 对比文档说明 `end-4/dots-hyprland`、Isabel 和当前 Axiom 在桌面环境上的主要差异。
- `docs/rfc.md` 提出从当前 Axiom 演进到目标状态的分阶段路径，包含范围、非目标、风险、验证和回滚。
- 本任务保持 design-only：不实现任何 Nix、Hyprland、Quickshell 或运行时配置改动。
- 保留或总结 subagent 研究证据，方便评审者追溯 RFC 依据。

## 假设

- 当前 Axiom 指本仓库的 `hosts/axiom/default.nix` 以及活跃桌面模块。
- Isabel 指本仓库已有 Isabel 研究和之前 Axiom 产品桌面任务证据；除非对比需要，否则不重新完整审计 Isabel。
- `end-4/dots-hyprland` 应作为产品和架构参考，而不是整体复制对象。
- 本地 wiki 输出先放在任务文档中，并用于 Legion wiki 收口写回；在 RFC 评审前不直接变成未经评审的永久 current-truth 页面。

## 约束

- 必须使用 subagent 研究 `https://github.com/end-4/dots-hyprland`。
- 本任务不实现配置改动。
- 结论必须绑定到可观察的上游文件、本地 Axiom 文件或已有 Isabel 任务证据。
- 任何演进路径都必须保持 Darwin 隔离和现有 Axiom host 边界。
- 优先选择分阶段、可回滚采用方式，而不是整体替换现有 dotfiles 架构。

## 范围

- 研究 `end-4/dots-hyprland` 的桌面环境配置。
- 在 `.legion/tasks/dots-hyprland-desktop-rfc/docs/` 下生成任务内 wiki/reference 材料。
- 与 Isabel 和当前 Axiom 桌面配置做对比。
- 为未来实现任务撰写 RFC，说明 Axiom 如何演进到选定目标状态。
- 生成 walkthrough 并完成 Legion wiki 收口写回。

## 非目标

- 不直接实现 Axiom 改动。
- 不整体导入 `end-4/dots-hyprland`、Isabel 或任何上游框架。
- 不完整记录每个与桌面产品面无关的上游包或脚本。
- 不对 `end-4/dots-hyprland` 做实时运行验证。
- 本 design-only 任务不走实现变更的 PR 生命周期。

## 设计概要

- 把 `end-4/dots-hyprland` 作为候选目标状态参考，并将其桌面产品模型提炼成紧凑 wiki。
- 从架构和用户可见桌面能力层面对比：compositor/session、shell、launcher、notifications、controls、theming、wallpapers、portals、media、app rules、input 和 maintainability。
- 用 Isabel 作为已研究过的产品基线，用 Axiom 作为当前实现基线。
- 推荐一个分阶段 Axiom 演进路径：保留现有 Nix-native 边界，只采用能提升桌面产品体验的目标能力。

## 风险

- 上游仓库可能很大、变化快、脚本较多，不适合精确复刻。
- AGS/Quickshell/shell framework 的差异可能意味着功能等价比技术等价更重要。
- 视觉 polish 有主观性；RFC 必须区分产品能力和审美偏好。
- Axiom 已经有本地 Quickshell 工作，因此 RFC 必须避免在增量扩展更安全时提出重写。

## 阶段

- 头脑风暴：物化本任务契约和状态检查清单。
- 研究：派 subagent 检查 `end-4/dots-hyprland` 并返回结构化发现。
- RFC 设计：撰写任务内 wiki、对比文档和 RFC。
- RFC 评审：进行对抗性设计评审，并按需更新。
- 报告：生成面向评审者的走读文档。
- Wiki 写回：写入 Legion wiki 收口总结，并按需更新索引/current-truth 入口。
