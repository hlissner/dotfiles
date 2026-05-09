# Review Change：Axiom Quickshell Side Dock Regression

日期：2026-05-09
结论：PASS

## Blocking Findings

无。

## Review Notes

- PASS：修复是最小 QML structure change，只在原 dock `PanelWindow` 后关闭第一个 `Variants`，再为 notification panel 增加第二个独立 `Variants`。
- PASS：每个 `Variants` 现在只有一个 `PanelWindow` delegate，符合本任务对 side dock 回归的根因假设。
- PASS：没有修改 notification center business logic、service module、Hyprland/UWSM/greetd/session ownership 或 fallback tools。
- PASS：Axiom toplevel build 和 service ownership eval 通过。

## Security Lens

未触发新的 security review。此修复不改变通知数据处理、持久化、外部命令、权限、session ownership 或 trust boundary。

## Residual Risk

- 当前环境无法提供 Wayland layer-shell backend，因此 side dock 可见性和 notification panel toggle 仍需在真实 Axiom Hyprland session 中确认。
- 如果 Quickshell 对多个 `Variants` 也有未记录限制，下一步应把两个 windows 放进一个 explicit component/delegate wrapper，而不是恢复 sibling `PanelWindow`。

## Evidence Reviewed

- `config/quickshell/axiom-shell/shell.qml`
- `.legion/tasks/axiom-quickshell-side-dock-regression/docs/test-report.md`
