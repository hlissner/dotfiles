## 摘要

- 添加 RFC-only 研究，把 `end-4/dots-hyprland` 作为 Axiom Hyprland + Quickshell 桌面的目标状态参考。
- 记录任务内 llm-wiki、与 Isabel/当前 Axiom 的三方对比，以及分阶段 Axiom-native 演进路径。
- 完成 RFC 评审，结论 PASS，无阻塞问题。

## 评审备注

- 模式：rfc-only；不包含运行时配置改动。
- 关键决策：通过增量能力等价演进，而不是导入上游文件或 installer 行为。
- 第一个未来实现应只聚焦 Stage 1 notification/shell-state，除非明确扩大范围。

## 证据

- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC 评审：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- 走读：`.legion/tasks/dots-hyprland-desktop-rfc/docs/report-walkthrough.md`
