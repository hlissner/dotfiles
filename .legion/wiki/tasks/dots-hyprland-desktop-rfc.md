# Dots Hyprland 桌面 RFC

状态：RFC-only 设计已完成
任务：`.legion/tasks/dots-hyprland-desktop-rfc/`

## 摘要

研究 `end-4/dots-hyprland`，将其作为 Axiom Hyprland + Quickshell 桌面的目标状态参考。本任务产出了任务内 llm-wiki、与 Isabel/当前 Axiom 的三方对比，以及用于未来 Axiom 演进的已评审 RFC。

## 当前有效结论

- `end-4/dots-hyprland` 应被视为完整 Hyprland 产品桌面的能力地图，而不是整体导入源。
- Axiom 应保留 Nix-native 架构、UWSM session path、systemd user service ownership、declarative monitors 和 local Quickshell source。
- 推荐未来路线是 Axiom-native 增量能力等价：先做 notification center，再做 shell search/actions，再做 quick controls/OSD，之后再考虑可选 dynamic theming 和 power-user extensions。
- 第一个未来实现任务应只聚焦 Stage 1，除非用户明确扩大范围。
- AI/cloud、clipboard persistence、OCR/translation 和 dynamic theming 都应延后，直到 privacy/state/rollback boundaries 明确。

## 验证

- 上游研究由 subagent 对 `end-4/dots-hyprland` 快照 `bebf66da89cd2afa4738da47fb3a0a9fa5af7035` 执行。
- RFC review 结论：PASS，无阻塞问题。
- 没有修改生产或运行时配置。

## 残余风险

- 如果不强制组件边界，Quickshell service growth 可能变成本地 framework。
- 如果 retention 和 disable behavior 不明确，notification 和 clipboard history 可能暴露敏感数据。
- 如果在 state model 设计前采用 dynamic theming，可能造成 generated-state ownership 混乱。
- 未来实现者不能把上游 mutable installer 或非 UWSM session assumptions 复制进 Axiom。

## 相关原始材料

- 计划：`.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- 研究：`.legion/tasks/dots-hyprland-desktop-rfc/docs/research.md`
- llm-wiki：`.legion/tasks/dots-hyprland-desktop-rfc/docs/llm-wiki-dots-hyprland.md`
- 对比：`.legion/tasks/dots-hyprland-desktop-rfc/docs/comparison.md`
- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC 评审：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- 走读：`.legion/tasks/dots-hyprland-desktop-rfc/docs/report-walkthrough.md`
