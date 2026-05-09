# 走读：Dots Hyprland 桌面 RFC

> 模式：rfc-only
> 日期：2026-05-09

## 变更内容

- 创建 design-only Legion 任务，用于研究 `end-4/dots-hyprland` 并定义 Axiom 如何向该目标状态演进。
- 添加任务内 llm-wiki，记录上游桌面配置。
- 添加 `end-4/dots-hyprland`、Isabel 和当前 Axiom 的对比。
- 添加 RFC，提出增量 Axiom-native 能力等价路径，而不是整体导入上游。
- 执行 RFC 评审；结论 PASS，无阻塞问题。

## 评审阅读顺序

- 先读 `docs/rfc.md`，了解决策、目标状态、分阶段路径、验证、回滚和安全边界。
- 再读 `docs/comparison.md`，了解三方桌面环境对比。
- 再读 `docs/llm-wiki-dots-hyprland.md`，了解上游能力地图。
- 再读 `docs/research.md`，了解来源、本地上下文和采用约束。
- 最后读 `docs/review-rfc.md`，了解 PASS 评审和残余风险。

## 决策概要

- 选择路径：Axiom-native 增量能力等价。
- 第一个未来实现切片：只做 Stage 1，即 shell state 和 notification center；除非用户明确合并 Stage 1 和 Stage 2。
- 拒绝路径：整体导入 `end-4/dots-hyprland`，原因是 mutable installer assumptions、UWSM conflict、broad dependencies 和 reviewability risk。
- 延后路径：dynamic theming、OCR/translation、clipboard persistence、AI/cloud features，直到 core shell capabilities 稳定且 privacy/state boundaries 明确。

## 证据

- 任务契约：`.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- 研究记录：`.legion/tasks/dots-hyprland-desktop-rfc/docs/research.md`
- 上游 wiki：`.legion/tasks/dots-hyprland-desktop-rfc/docs/llm-wiki-dots-hyprland.md`
- 对比文档：`.legion/tasks/dots-hyprland-desktop-rfc/docs/comparison.md`
- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- 评审记录：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`

## 残余风险

- 如果不保持小组件边界，未来 Quickshell growth 可能过大。
- Notification 和 clipboard history 在持久存储前需要明确 retention 和 disable behavior。
- Dynamic theming 如果过早采用，可能模糊 generated-state ownership。
- `end-4/dots-hyprland` 必须继续作为 capability reference；它的 session/install model 与 Axiom 冲突。
