# Axiom Quickshell Side Dock Regression

状态：实现已完成，PR-backed delivery 中
任务：`.legion/tasks/axiom-quickshell-side-dock-regression/`

## 摘要

修复 PR #14 后 Axiom 左侧 side dock 不显示的回归。根因判断为 `shell.qml` 在同一个 `Variants` block 中放入了两个 sibling `PanelWindow`，导致 Quickshell per-screen delegate 结构不可靠。修复后 side dock 和 notification panel 各自位于独立 `Variants { model: Quickshell.screens }` block。

## 当前有效结论

- Axiom Quickshell 每个 `Variants` block 应只承载一个 per-screen `PanelWindow` delegate。
- Side dock 必须保持默认可见的 persistent panel；notification panel 应作为独立 per-screen panel，由 dock notification button 控制 `visible`。
- 不需要修改 Quickshell service、Hyprland/UWSM/greetd/session ownership 来修复此回归。

## 验证

- `git diff --cached --check`：PASS。
- QML structure grep：PASS，`shell.qml` 现在有两个独立 `Variants` 和两个 `PanelWindow`。
- Quickshell service ownership eval：PASS，仍绑定 `hyprland-session.target`。
- Axiom toplevel build：PASS。
- Headless/offscreen Quickshell smoke：受限于无 `PanelWindow` backend；真实 Axiom Hyprland session 仍需确认 dock 可见和 notification panel toggle。

## 残余风险

- 当前验证环境不能显示 layer-shell UI，无法自动证明视觉回归已完全消失。
- 如果真实 session 仍不显示 dock，需要进一步检查 Quickshell 多 `Variants` 组合是否也受限，并考虑 explicit wrapper component。

## 相关材料

- 任务契约：`.legion/tasks/axiom-quickshell-side-dock-regression/plan.md`
- 验证：`.legion/tasks/axiom-quickshell-side-dock-regression/docs/test-report.md`
- Review：`.legion/tasks/axiom-quickshell-side-dock-regression/docs/review-change.md`
- Walkthrough：`.legion/tasks/axiom-quickshell-side-dock-regression/docs/report-walkthrough.md`
