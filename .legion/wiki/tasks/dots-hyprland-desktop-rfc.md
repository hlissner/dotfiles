# Dots Hyprland Desktop Phase 4

状态：Phase 4 implementation substrate 已完成，PR lifecycle 进行中
任务：`.legion/tasks/dots-hyprland-desktop-rfc/`

## 摘要

该任务最初是 design-only 的 end4 desktop RFC。2026-05-09 continuation 明确改变方向：以用户提供的 `end4.md` 为当前阶段和主题真源，允许彻底改写 RFC，并继续实现第四阶段。

当前结果把历史 RFC 改写为 end4 `ii` / `IllogicalImpulseFamily` 目标体验，并实现 Phase 4 的 NixOS/user-service substrate：packages、services、groups、i2c/DDC、keyring、polkit、power profiles、`cliphist` watcher、fallback tools，以及旧 Axiom guide/autumnal Hyprland visual cleanup。

## 当前有效结论

- `end4.md` 是本任务 continuation 的阶段和主题真源；历史 Axiom-native incremental shell RFC 已被当前 RFC supersede。
- Axiom 当前目标 UX 是 end4 `ii` / `IllogicalImpulseFamily`，不是旧 Axiom dock/guide/button 或 `autumnal` 桌面视觉。
- NixOS 仍然是 host facts、UWSM/greetd/portal ownership、service dependencies、permissions、runtime package closure 和 generated-state boundaries 的真源。
- Phase 4 的最小正确实现是声明式 service substrate；它不等价于完整 `ii/shell.qml` runtime import。
- `origin/master` 当前仍缺 end4 `ii` source tree，因此 `ii/shell.qml` runtime load 是 prior-phase debt，而不是本 Phase 4 PR 用旧 shell 补回的目标。
- `cliphist` watcher 默认使用 `wl-paste --type text --watch cliphist store`；display/readback 有 shell limits，但 cliphist database retention pruning 尚未实现。

## 实现要点

- `modules/desktop/quickshell.nix` 扩展 Qt/Kirigami/QML、Material Symbols、`googlesans-code`、matugen/wallpaper、media/resource/control、network/Bluetooth、brightness/DDC、clipboard、polkit、power-profile 和 fallback tool package closure。
- `modules/desktop/quickshell.nix` 声明 `phase4Services.enable`、`polkitAgent.enable` 和 `search.clipboard.backend` rollback knobs。
- Axiom 启用 gnome-keyring；keyring module 禁用 gcr SSH agent，避免与 `programs.ssh.startAgent` 冲突。
- `autumnal` 保留为非桌面 theme module，但不再 import Hyprland visual hook。
- Old guide docs/config/link/launcher/QML guide actions 已删除或移除。
- Transitional `axiom-shell` helpers 现在支持 `cliphist` list/copy/clear、brightness、power profiles 和 resource status，直到 end4 `ii` tree 完成迁移。

## 验证

- RFC review：PASS。
- Change review：PASS，security lens 覆盖 clipboard history、keyring/polkit、groups 和 i2c permissions。
- Targeted `nix eval`：确认 Phase 4 service/package/group/keyring/polkit/i2c/cliphist wiring。
- Python helper syntax parse：PASS。
- Active source grep：active shell/module path 无旧 guide references。
- `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`：PASS。

## 残余风险

- Live Quickshell/Hyprland runtime checks 未执行；需要在 Axiom graphical session 中验证。
- `ii/shell.qml` runtime load 未验证，因为当前 base 缺 Phase 1 `ii` source。
- `cliphist` retention policy 未实现 pruning；需要后续定义 retention/clear UX。
- `video`/`input`/`i2c` groups 和 `i2c-dev` 是本地硬件权限扩展，必须保留在 Axiom desktop control scope 内。

## 相关原始材料

- 计划：`.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- RFC：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`
- RFC 评审：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-rfc.md`
- 测试报告：`.legion/tasks/dots-hyprland-desktop-rfc/docs/test-report.md`
- Change review：`.legion/tasks/dots-hyprland-desktop-rfc/docs/review-change.md`
- Walkthrough：`.legion/tasks/dots-hyprland-desktop-rfc/docs/report-walkthrough.md`
- PR body：`.legion/tasks/dots-hyprland-desktop-rfc/docs/pr-body.md`
