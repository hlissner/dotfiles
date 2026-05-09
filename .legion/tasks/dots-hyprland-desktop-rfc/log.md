# Dots Hyprland 桌面 RFC 日志

## 2026-05-09

- 因为请求没有指定既有任务目录，进入 Legion workflow 并创建新的 design-only 任务。
- 与用户确认本轮只产出文档：任务契约、llm-wiki/wiki 材料、对比和 RFC。
- 在 `.legion/tasks/dots-hyprland-desktop-rfc/` 下物化任务契约。
- 派 subagent 研究 `end-4/dots-hyprland`；记录上游快照为 `bebf66da89cd2afa4738da47fb3a0a9fa5af7035`。
- 写入 `docs/research.md`、`docs/llm-wiki-dots-hyprland.md`、`docs/comparison.md` 和 `docs/rfc.md`。
- 执行 RFC 评审；结论为 PASS，无阻塞问题。将非阻塞安全建议折回 `docs/rfc.md`，并记录 `docs/review-rfc.md`。
- 生成 rfc-only 评审 walkthrough 和 PR body 风格摘要：`docs/report-walkthrough.md`、`docs/pr-body.md`。
- 完成 Legion wiki 写回：`.legion/wiki/tasks/dots-hyprland-desktop-rfc.md`、`decisions.md`、`patterns.md`、`index.md` 和 `log.md`。

## 2026-05-09 Phase 4 continuation

- 用户明确要求使用 Legion workflow 继续 `dot-hyprland-desktop-rfc` 第四阶段，并说明主题相关事项以 `end4.md` 为准，可彻底修改 RFC 后继续实现。
- 恢复到既有任务目录 `.legion/tasks/dots-hyprland-desktop-rfc/`；发现历史契约仍是 design-only，和当前实现请求发生漂移。
- 按 `git-worktree-pr` envelope 从 `origin/master` 创建隔离 worktree：`.worktrees/dots-hyprland-desktop-rfc/`，分支 `legion/dots-hyprland-desktop-rfc-phase4-services`。
- 将任务契约重写为 Phase 4 实现任务：补齐 end4 launcher、overview、左右侧栏、控制中心、通知中心及其 NixOS 服务能力，并把 `end4.md` 的主题方向作为当前真源。
- 重写 `docs/rfc.md`：采用 `end4.md` 的 Phase 1-6 模型，明确 Phase 4 当前实现只补齐声明式服务/依赖/权限层，旧 Axiom dock/guide/button 和 `autumnal` 桌面视觉不再是目标兼容面。
- 执行 RFC 评审；结论 PASS，无阻塞问题。非阻塞建议要求 implementation notes 明确 `cliphist` 默认行为、字体映射、runtime check 限制和 notification daemon conflict handling。
- 检查当前 `origin/master` 基线：仍包含 `config/quickshell/axiom-shell/*`，未包含 end4 `ii/shell.qml`；因此本轮实现按 RFC 选择的最小切片补齐 Phase 4 service substrate，并把 `ii` source 缺口记录为 prior-phase debt。
- 实现 Phase 4 Nix 能力：扩展 Quickshell Qt/Kirigami/font/runtime package closure，添加 `cliphist` clipboard watcher backend、power-profiles-daemon、polkit agent、keyring、i2c/DDC、video/input/i2c groups、wallpaper/theme runtime tools和 media/resource/control fallback tools。
- 移除旧 Axiom guide 入口：删除 runtime guide 文件和 docs guide，停止 link `axiom-desktop/guide.md`，移除 Hyprland guide launcher、shell `NIX`/`HELP`/guide actions。
- 停止 `autumnal` 写入 Hyprland 桌面主视觉：保留 theme module 作为非桌面 fallback，但不再 import `modules/themes/autumnal/hyprland.nix`。
- 给当前过渡 Quickshell helper 补齐 brightness、power profile 和 resource status 能力；search clipboard backend 改为读取/复制/清理 `cliphist`。
- 验证阶段发现并修复两个实现问题：gnome-keyring 默认 gcr SSH agent 与 Axiom `programs.ssh.startAgent` 冲突；`google-fonts` bundle 过大导致 build 尝试超时。修复为禁用 gcr SSH agent，并用 `googlesans-code` + `material-symbols` 映射 end4 字体需求。
- 记录 `docs/test-report.md`。最终 `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` 通过；targeted `nix eval` 和 Python helper syntax parse 通过。Live Quickshell/Hyprland runtime checks 因不在 Axiom 图形会话中未执行。
- 执行 change review；结论 PASS。按非阻塞建议移除未启动的 `hyprpolkitagent` 包、更新 RFC 状态，并在 test report 中记录 `cliphist` retention caveat。清理后 rerun targeted eval 和 Axiom toplevel build 均通过。
- 生成 implementation-mode walkthrough 和 PR body：`docs/report-walkthrough.md`、`docs/pr-body.md`。
- 完成 Legion wiki writeback：更新 task summary、decisions、patterns、index、log，并新增 maintenance backlog。

## 2026-05-09 complete end4 import continuation

- 用户拒绝 Phase 4 substrate-only 降级，并明确要求从 `https://github.com/end-4/dots-hyprland` 补完整。
- 确认当前机器 hostname 是 `axiom`，但工具 shell 为 `XDG_SESSION_TYPE=tty`，缺少 `WAYLAND_DISPLAY` 和 `HYPRLAND_INSTANCE_SIGNATURE`；后续验证必须区分 host identity 和 live Hyprland session。
- 按 `git-worktree-pr` envelope 从 `origin/master` 创建新 worktree：`.worktrees/dots-hyprland-desktop-rfc/`，分支 `legion/dots-hyprland-desktop-rfc-end4-complete`。
- 重写任务契约：本轮 acceptance 是导入并加载 end4 `ii/shell.qml`、matugen/theme/wallpaper chain、Hyprland layering 和 Phase 4 核心 UI surfaces；substrate-only 不再有效。
- 重写 `docs/rfc.md`：选择 vendor upstream required source + Nix wiring，拒绝 substrate-only 和运行 upstream setup。
- RFC review 初次 FAIL：source import boundary 和无 live compositor 时的 Quickshell/QML loadability 验证不够明确。已补充 import manifest 规则、省略规则、hypridle/hyprlock 落点和静态/直接 Quickshell 验证要求。
- RFC re-review PASS。可进入 implementation。
- 从上游 commit `bebf66da89cd2afa4738da47fb3a0a9fa5af7035` 导入 `dots/.config/quickshell/ii`、`matugen`、`fuzzel/fuzzel.ini`、Hyprland layering、`hypridle.conf` 和 `hyprlock.conf`，未运行 upstream `setup`。
- 写入 `docs/import-manifest.md`，记录 copied paths、omitted installer/generated/state/secret paths 和 Nix-generated override paths。
- 将 Axiom Quickshell 默认 `configName` 切到 `ii`，链接 `quickshell/ii`、`matugen`、`fuzzel`，并把旧 `axiom-shell` 标记为 deprecated historical source。
- 将 upstream Hyprland exec ownership 切给 Nix：`$dontLoadDefaultExecs = 1`，通过 Nix 生成 `custom/env.conf`、`variables.conf`、`execs.conf`、`rules.conf`、`keybinds.conf`、`general.conf`、`monitors.conf` 和 `workspaces.conf`。
- 删除导入中的 generated color outputs，并把 video wallpaper restore script 改到 XDG state generated path，避免把 runtime state 写回 repository-managed config source。
- 禁用外部 KDE polkit agent 默认启动，让 imported `ii` 的 `Quickshell.Services.Polkit` 提供 polkit-facing UX；`security.polkit` 仍由 NixOS 启用。
- 验证时发现 `ii/modules/common/widgets/shapes` 是上游 git submodule，补充导入 `end-4/rounded-polygon-qmljs` at `e31ec4cb4ebf6a46b267f5c42eabf6874916fa16`，未复制 submodule `.git` 元数据。
- 验证时发现 pinned `quickshell 0.2.1` 缺少 imported `ii` 需要的 `Quickshell.Services.Polkit`，改为在 Nix 中构建 `quickshell 0.3.0`，并包装 Qt QML/plugin import paths。
- 记录 `docs/test-report.md`。最终 `env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` 通过；QML local import scan 通过；headless Quickshell smoke 到达 `No PanelWindow backend loaded`，说明当前 TTY 缺少 live Wayland/layershell backend 而不是缺 `ii` source/import。
- 执行 change review；结论 PASS，无阻塞项。Security lens 已覆盖 polkit/auth UX、keyring/API credentials、clipboard、hardware-control permissions、AI/cloud modules 和 live-session scripts；剩余风险记录为 live Wayland validation、cliphist retention、AI/cloud defaults、上游 Arch/KDE/kitty/fish-oriented optional commands，以及 `.upstream/` 继续保持未提交。
- 生成 implementation-mode reviewer walkthrough 和 PR body：`docs/report-walkthrough.md`、`docs/pr-body.md`。内容只重组已有证据，记录 end4 `ii` 导入、Nix/Hyprland wiring、repository-local PASS 验证和 live-session residual risks。
- 完成 Legion wiki writeback：更新 task summary、desktop decisions、End4 import pattern、maintenance backlog、index 和 wiki log。当前 wiki 真源已从 Phase 4 substrate 改为 complete end4 `ii` source import + Nix-owned integration。
