# Axiom Quickshell Search and Actions

状态：实现已完成，PR-backed delivery 中
任务：`.legion/tasks/axiom-quickshell-search-actions/`

## 摘要

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 2，本任务把 Axiom launcher 入口从 Fuzzel-first 演进为 Quickshell-owned search/action panel。新 surface 覆盖 desktop apps、declared local actions、web search、calculator、emoji 和 clipboard history，同时保留 Fuzzel direct fallback。

## 当前有效结论

- Axiom Stage 2 search/actions 的 primary UI belongs to repository-owned Quickshell, not Rofi/DMS or upstream launcher frameworks.
- `APP` dock entry opens Quickshell search; `Super+Space` attempts Quickshell IPC and falls back to Fuzzel; `Super+Shift+Space` remains direct Fuzzel.
- Provider execution must stay fixed-verb based: QML invokes static argv arrays or `axiom-search-helper` subcommands, not query-derived shell text.
- Apps are discovered from XDG desktop entries and launched only after desktop ID validation.
- Clipboard history is intentionally persistent for this single-user workstation contract, but it is capped, clearable, disableable through `modules.desktop.quickshell.search.clipboard.enable`, and removable from user-local XDG state.
- Stage 1 notification center and side-dock layout remain separate `Variants` / `PanelWindow` surfaces.

## 验证

- Python helper syntax and provider smoke: PASS.
- Isolated clipboard add/list/copy/clear/disabled smoke with repo-local state and fake `wl-copy`: PASS.
- Scope checks: no upstream installer/downloaded scripts, no Rofi/DMS primary launcher path, Fuzzel fallback retained, no query-derived `sh -lc` in search implementation.
- Nix parse/eval and Axiom toplevel build: PASS.
- `Hyprland --verify-config -c config/hypr/hyprland.conf`: PASS.
- Readiness review: PASS.

## 残余风险

- Live Axiom Wayland/layer-shell behavior was not verified in the headless environment: panel focus, dock `APP`, IPC open/toggle, real app launch, real clipboard copy/persistence, notification regression, and stopped-Quickshell fallback still need session checks.
- `Super+Space` fallback handles IPC command failure, but not necessarily IPC success followed by focus failure; direct Fuzzel remains available.
- Clipboard history stores sensitive text persistently by design; clear/disable controls should be used when privacy is preferred.

## 相关材料

- 任务契约：`.legion/tasks/axiom-quickshell-search-actions/plan.md`
- RFC：`.legion/tasks/axiom-quickshell-search-actions/docs/rfc.md`
- RFC Review：`.legion/tasks/axiom-quickshell-search-actions/docs/review-rfc.md`
- 验证：`.legion/tasks/axiom-quickshell-search-actions/docs/test-report.md`
- Review：`.legion/tasks/axiom-quickshell-search-actions/docs/review-change.md`
- Walkthrough：`.legion/tasks/axiom-quickshell-search-actions/docs/report-walkthrough.md`
- 设计来源：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
