# Axiom Quickshell Quick Controls and OSD

状态：实现已完成，PR-backed delivery 中
任务：`.legion/tasks/axiom-quickshell-quick-controls-osd/`

## 摘要

基于已评审通过的 `dots-hyprland-desktop-rfc` Stage 3，本任务把 Axiom dock 的 quick-control entries 从 direct external tool launchers 推进为 Quickshell-owned quick-controls panel，并新增 Quickshell OSD path for volume/brightness/media feedback。实现保留 Stage 1 notification center、Stage 2 search/actions、外部 fallback tools 和 existing media-key fallback behavior。

## 当前有效结论

- Axiom Stage 3 quick controls 的 primary UI belongs to repository-owned Quickshell, with Nix-owned helper/package wiring and Hyprland limited to keybinding routing.
- Quick controls first pass uses shallow helper-backed status/actions, not full DBus settings-app parity. Wi-Fi onboarding, Bluetooth pairing, and deep audio device switching remain fallback-led.
- Dock `WIFI`、`BT`、`VOL` 和 `PWR` entries should open relevant quick-controls sections; fallback buttons for `nm-connection-editor`、`blueman-manager`、`pavucontrol`、`wlogout` and direct actions remain visible.
- Volume/brightness OSD still goes through the existing `hey .osd` state-changing path, now attempting Quickshell OSD IPC before `notify-send` fallback.
- Media keys route through fixed `axiom-control-helper media ...` verbs that run `playerctl` actions before attempting Quickshell OSD.
- New control actions must stay fixed-verb/static-argv; no generic command runner or remote/downloader path is introduced.

## 验证

- Helper syntax/status/media smoke: PASS.
- OSD zsh syntax: PASS.
- `git diff --check`: PASS.
- Nix module parse, service ownership eval, toplevel eval and full Axiom build: PASS.
- `Hyprland --verify-config -c config/hypr/hyprland.conf`: PASS.
- Quickshell CLI and `qmllint` on modified QML: PASS.
- Scope/fallback grep, `Variants`/`PanelWindow` count, and helper subprocess-shape checks: PASS.
- Readiness review: PASS.

## 残余风险

- Live Axiom Wayland/layer-shell behavior was not verified headlessly: quick-controls focus/layer placement, multi-screen visibility, panel interaction and rapid OSD IPC timing still need real-session checks.
- Disruptive controls were intentionally not run during verification: Wi-Fi toggle, Bluetooth power toggle, audio volume mutation, lock, DPMS off and `wlogout`.
- Real behavior may vary with availability/output of `nmcli`, `bluetoothctl`, `pamixer`, `playerctl` and active hardware/services; unavailable states should degrade to fallback tools.

## 相关材料

- 任务契约：`.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md`
- RFC：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/rfc.md`
- RFC Review：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-rfc.md`
- 验证：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/test-report.md`
- Review：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-change.md`
- Walkthrough：`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/report-walkthrough.md`
- 设计来源：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
