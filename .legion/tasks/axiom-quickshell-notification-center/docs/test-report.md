# Test Report：Axiom Quickshell Notification Center

日期：2026-05-09

## 结论

PASS，带一个 headless runtime 限制说明。

本轮验证证明：Axiom NixOS 配置仍可构建，Quickshell service ownership 未漂移，新增 QML 文件被纳入 flake source，staged diff 无 whitespace error，且没有引入 Stage 2/search/clipboard/dynamic-theme 相关 QML surface。完整通知收发、action invocation 和 dismiss/clear runtime 行为仍需在真实 Axiom Wayland/Hyprland session 中手测。

review-change 前置审查后做过一次小修复：`clearNotifications()` 不再依赖 `ObjectModel.values.slice()`，改用倒序索引 dismiss。修复后已重跑 staged whitespace、service ownership eval、Axiom toplevel build、Quickshell headless/offscreen smoke 和 scope grep。

## 为什么选择这些验证

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 是本变更最强的本地验证；它覆盖 NixOS module evaluation、Home Manager config linking、Quickshell package/service ownership，以及新增 QML source 是否进入 flake input。
- `nix eval` targeted service query 用于直接证明 `quickshell.service` 仍绑定到 `hyprland-session.target`，没有改变 RFC 要求的 UWSM/session boundary。
- `quickshell --path config/quickshell/axiom-shell` 在 headless/offscreen 环境下用于尽早捕获 QML 配置加载问题；该环境没有 PanelWindow backend，因此不能替代真实 session 手测。
- `git diff --cached --check` 和 scope grep 用于防止交付分支带入 whitespace error 或超出 Stage 1 的 QML surface。

## 执行命令

### Staged diff whitespace

命令：

```sh
git diff --cached --check
```

结果：PASS，无输出。

备注：初次运行发现复制进分支的 RFC 证据文件有既有 trailing whitespace；已在 worktree 中清理后重跑通过。

### Quickshell service ownership eval

命令：

```sh
XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-notification-center/docs/cache" nix eval --impure --json --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-quickshell-notification-center"; cfg = flake.nixosConfigurations.axiom.config; in { configName = cfg.modules.desktop.quickshell.configName; execStart = cfg.systemd.user.services.quickshell.serviceConfig.ExecStart; wantedBy = cfg.systemd.user.services.quickshell.wantedBy; after = cfg.systemd.user.services.quickshell.after; partOf = cfg.systemd.user.services.quickshell.partOf; linkedQuickshellConfig = cfg.home.configFile."quickshell/axiom-shell".recursive; }'
```

结果：PASS。review follow-up 修复后重跑仍为 PASS。

关键输出：

```json
{
  "after": ["hyprland-session.target"],
  "configName": "axiom-shell",
  "execStart": "/nix/store/62wamvsss1g7vayzci6y934qy8qcmlmp-axiom-quickshell/bin/quickshell --config axiom-shell",
  "linkedQuickshellConfig": true,
  "partOf": ["hyprland-session.target"],
  "wantedBy": ["hyprland-session.target"]
}
```

说明：验证了本任务未改变 `modules/desktop/quickshell.nix` 的 service owner、config name 或 `hyprland-session.target` 边界。

### Axiom NixOS toplevel build

命令：

```sh
XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-notification-center/docs/cache" nix build --impure --no-link ".#nixosConfigurations.axiom.config.system.build.toplevel"
```

结果：PASS。

观察到的既有 evaluation warnings：

- `specialArgs.pkgs` warning。
- `mesa.drivers` deprecation warning。
- `hardware.pulseaudio` renamed to `services.pulseaudio` warning。
- `system` renamed/replaced by `stdenv.hostPlatform.system` warning。

这些 warning 与本任务的 Quickshell QML 变更无关，本轮未处理。

### Quickshell headless/offscreen smoke

命令：

```sh
QT_QPA_PLATFORM=offscreen XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-notification-center/docs/cache" timeout 10s /nix/store/62wamvsss1g7vayzci6y934qy8qcmlmp-axiom-quickshell/bin/quickshell --path "config/quickshell/axiom-shell"
```

结果：EXPECTED LIMITATION。review follow-up 修复后重跑仍因同一 headless backend 限制停止。

关键输出：

```text
INFO: Launching config: "/home/c1/dotfiles/.worktrees/axiom-quickshell-notification-center/config/quickshell/axiom-shell/shell.qml"
ERROR: Failed to load configuration
ERROR:   caused by @shell.qml[157:5]: No PanelWindow backend loaded.
```

说明：命令能启动到配置加载，但 offscreen/headless Qt 没有 Quickshell `PanelWindow` backend，不能完成 layer-shell runtime smoke。没有看到 QML syntax error；真实通知收发和 panel 操作仍需在 Axiom Hyprland session 验证。

### Scope regression grep

命令：

```sh
rg -n "PersistentProperties|FileView|clipboard|search|DesktopEntries|dynamic|matugen|rofi|DMS" "config/quickshell/axiom-shell" --glob "*.qml"
```

结果：PASS，无匹配。review follow-up 修复后重跑仍无匹配。

说明：验证本任务没有把 Stage 2 search/actions、clipboard persistence、dynamic theming 或 legacy shell dependency 引入 QML surface。

## 未执行项

- 未在真实 Axiom Hyprland session 中发送测试通知，因为当前验证环境没有 Wayland layer-shell/notification runtime。
- 未执行 notification action callback 的端到端验证；需要在部署后用支持 actions 的通知客户端测试。
- 未执行 Hyprland config verification，因为本任务没有修改 Hyprland config、bindings、rules、session startup 或 monitor generation。

## 验证后清理

- 验证命令使用的 repo-local `docs/cache` 目录已删除，未作为交付物保留。
