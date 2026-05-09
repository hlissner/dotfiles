# RFC 评审：Dots Hyprland 桌面 RFC

> 结论：PASS
> 日期：2026-05-09

## 阻塞问题

无。

RFC 对未来实现任务而言已经足够清晰、有边界、可验证、可回滚。它选择了增量式 Axiom-native 采用路径，保留 Nix/UWSM/session 边界，拒绝整体导入上游，并定义了分阶段回滚路径。

## 已纳入的非阻塞建议

- RFC 已将第一个未来实现切片收窄为 Stage 1；除非用户明确合并 Stage 1 和 Stage 2。
- Stage 2 现在声明默认禁用任意脚本执行；在策略存在前只允许已评审的本地 actions。
- Stage 2 现在把持久 clipboard history 视为 opt-in，直到明确 retention、clear behavior 和 disable switches。

## 残余风险

- 如果不强制组件边界，Quickshell service growth 可能演变成大型本地 framework。
- 如果 storage/retention 未定义，clipboard 和 notification history 可能暴露敏感数据。
- Dynamic theming 如果不保持 optional 和 tightly scoped，可能造成 generated-state ownership 混乱。
- 上游 `end-4/dots-hyprland` 行为与 Axiom 的 UWSM/session model 冲突；未来实现必须继续把它当作能力参考，而不是导入源。
