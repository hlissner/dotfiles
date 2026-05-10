# Dots Hyprland Desktop Complete End4 Import

状态：historical；已由 `axiom-caelestia-shell-migration` supersede
任务：`.legion/tasks/dots-hyprland-desktop-rfc/`

## 摘要

该任务最初是 design-only 的 end4 desktop RFC，随后完成过 Phase 4 service substrate。用户拒绝 substrate-only / prior-phase debt 降级后，本轮 continuation 将目标改为完整导入并加载 upstream end4 `ii` 桌面源。

历史结果曾把 Axiom active shell 切到 repository-managed end4 `ii` / `IllogicalImpulseFamily`：导入 `quickshell/ii`、matugen、fuzzel、Hyprland layering、hypridle 和 hyprlock 源，同时继续让 NixOS 管理 host facts、services、generated overrides、permissions、rollback 和 mutable state boundaries。当前 active shell truth 已改为 Caelestia Shell。

## 当前有效结论

- Historical only: substrate-only 结论曾被用户明确拒绝；当时目标是完整 end4 `ii` source import 和 NixOS integration。
- Historical only: Axiom Quickshell 默认 runtime config 曾是 `ii`，不是旧 `axiom-shell`；当前 active shell truth 已由 `axiom-caelestia-shell-migration` 改为 Caelestia Shell。
- NixOS 仍然是 host facts、UWSM/greetd/portal ownership、service dependencies、permissions、runtime package closure、generated overrides 和 generated-state boundaries 的真源。
- Upstream end4 `setup` 不运行；installer scripts、generated color outputs、secrets、cache/state、local user JSON 和 live home mutation artifacts 不进入 Git。
- Imported `ii` 需要 `Quickshell.Services.Polkit`，因此 Axiom 在本任务中构建 wrapped Quickshell `0.3.0`，而不是继续使用缺少该 service 的 pinned `0.2.1`。
- `cliphist` watcher 默认使用 `wl-paste --watch cliphist store`；functionality 属于 end4 UI scope，但 database retention/pruning 仍是隐私 follow-up。

## 实现要点

- 从 upstream `end-4/dots-hyprland` commit `bebf66da89cd2afa4738da47fb3a0a9fa5af7035` 导入 `dots/.config/quickshell/ii`，并补入 rounded-polygon submodule `e31ec4cb4ebf6a46b267f5c42eabf6874916fa16`。
- 导入 `config/matugen`、`config/fuzzel/fuzzel.ini`、`config/hypr/hyprland.conf`、`config/hypr/hyprland/**`、`config/hypr/hypridle.conf`、`config/hypr/hyprlock.conf` 和 lock helper scripts。
- `modules/desktop/quickshell.nix` defaults `configName = "ii"`，links `quickshell/ii`、`matugen`、`fuzzel`，builds wrapped Quickshell `0.3.0`，并提供 Python env 给 imported helper scripts。
- `modules/desktop/hyprland.nix` 采用 upstream Hyprland source layering，并由 Nix 生成 `monitors.conf`、`workspaces.conf` 和 `hypr/custom/*.conf`；`$dontLoadDefaultExecs = 1` 保持 NixOS 对 session services 的 ownership。
- Generated color/theme/runtime outputs 保持在 XDG config/state/cache runtime path，不作为 repository source committed。
- External KDE polkit agent 默认关闭，polkit-facing UX 交给 imported `ii` 的 `Quickshell.Services.Polkit`，NixOS 仍启用 `security.polkit`。

## 验证

- RFC review：PASS。
- Repository-local verification：PASS。
- Targeted `nix eval`：确认 `configName = "ii"`、Quickshell `ExecStart`、linked sources 和 generated Hyprland variables。
- QML local import scan：577 个 QML 文件，missing local imports 为 0。
- Generated output 和 common-secret scans：PASS。
- Wrapped Quickshell package build：PASS。
- Headless Quickshell smoke 到达 `ii/shell.qml` 并解析 QML imports，随后在 TTY/offscreen 环境预期失败于 `No PanelWindow backend loaded`。
- `env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`：PASS。
- Change review：PASS，security lens 覆盖 polkit/auth UX、keyring/API credentials、clipboard、hardware-control permissions、AI/cloud modules 和 live-session scripts。

## 残余风险

- Live Quickshell/Hyprland runtime checks 未在本 TTY shell 执行；需要在 Axiom graphical session 中验证 restart、sidebars、overview/search、notifications、OSD、lock/session、wallpaper switching、polkit prompts、tray 和 hardware controls。
- `cliphist` retention policy 未实现 pruning；需要后续定义 retention、clear UX 和 disable behavior。
- Imported AI/cloud/function tooling powerful；需要后续更保守的 defaults、policy 或 documentation hardening。
- 一些 upstream optional commands 仍假设 KDE tools、`kitty`/`fish` 或 Arch-style commands；后续应 map 到 Axiom/Nix defaults 或隐藏 unsupported actions。
- `.upstream/end4-dots-hyprland` 只是本地 import evidence，必须保持未提交并在 PR final cleanup 前移除或保留为明确 local-only state。

## 相关原始材料

- 计划：`.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC 评审：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- Import manifest：`.legion/tasks/dots-hyprland-desktop-rfc/docs/import-manifest.md`
- 测试报告：`.legion/tasks/dots-hyprland-desktop-rfc/docs/test-report.md`
- Change review：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-change.md`
- Walkthrough：`.legion/tasks/dots-hyprland-desktop-rfc/docs/report-walkthrough.md`
- PR body：`.legion/tasks/dots-hyprland-desktop-rfc/docs/pr-body.md`
