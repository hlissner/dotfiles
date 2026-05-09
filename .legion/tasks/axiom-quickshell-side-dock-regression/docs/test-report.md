# Test Report：Axiom Quickshell Side Dock Regression

日期：2026-05-09

## 结论

PASS，带真实 Wayland session 验证缺口。

本轮验证证明：QML structure 已从一个 `Variants` 包含两个 sibling `PanelWindow` 修复为两个独立 `Variants`，每个 `Variants` 只有一个 `PanelWindow` delegate；Quickshell service ownership 未漂移；Axiom NixOS toplevel build 通过。headless/offscreen Quickshell 仍因无 `PanelWindow` backend 停在配置加载阶段，这是环境限制，不能替代真实 Axiom Hyprland session 可见性测试。

## 执行命令

### Staged diff whitespace

```sh
git diff --cached --check
```

结果：PASS，无输出。

### QML structure check

```sh
rg -n "Variants \\{|PanelWindow \\{" "config/quickshell/axiom-shell/shell.qml"
```

结果：PASS。

关键输出：

```text
154:  Variants {
157:    PanelWindow {
282:  Variants {
285:    PanelWindow {
```

说明：dock 和 notification panel 现在分别位于独立 `Variants` block，不再是同一个 `Variants` 下的 sibling delegate。

### Quickshell service ownership eval

```sh
XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-side-dock-regression/docs/cache" nix eval --impure --json --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-quickshell-side-dock-regression"; cfg = flake.nixosConfigurations.axiom.config; in { configName = cfg.modules.desktop.quickshell.configName; execStart = cfg.systemd.user.services.quickshell.serviceConfig.ExecStart; wantedBy = cfg.systemd.user.services.quickshell.wantedBy; after = cfg.systemd.user.services.quickshell.after; partOf = cfg.systemd.user.services.quickshell.partOf; linkedQuickshellConfig = cfg.home.configFile."quickshell/axiom-shell".recursive; }'
```

结果：PASS。

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

### Axiom NixOS toplevel build

```sh
XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-side-dock-regression/docs/cache" nix build --impure --no-link ".#nixosConfigurations.axiom.config.system.build.toplevel"
```

结果：PASS。

观察到的既有 warnings：

- `specialArgs.pkgs` warning。
- `mesa.drivers` deprecation warning。
- `hardware.pulseaudio` renamed to `services.pulseaudio` warning。
- `system` renamed/replaced by `stdenv.hostPlatform.system` warning。

这些 warning 与本回归修复无关。

### Quickshell headless/offscreen smoke

```sh
QT_QPA_PLATFORM=offscreen XDG_CACHE_HOME="$PWD/.legion/tasks/axiom-quickshell-side-dock-regression/docs/cache" timeout 10s /nix/store/62wamvsss1g7vayzci6y934qy8qcmlmp-axiom-quickshell/bin/quickshell --path "config/quickshell/axiom-shell"
```

结果：EXPECTED LIMITATION。

关键输出：

```text
INFO: Launching config: "/home/c1/dotfiles/.worktrees/axiom-quickshell-side-dock-regression/config/quickshell/axiom-shell/shell.qml"
ERROR: Failed to load configuration
ERROR:   caused by @shell.qml[157:5]: No PanelWindow backend loaded.
```

说明：当前环境没有 Quickshell `PanelWindow` backend；真实 dock 可见性仍需在 Axiom Hyprland session 验证。

## 未执行项

- 未在真实 Axiom Hyprland session 中确认左侧 side dock 可见；这是本 bug 最关键的人工验收项。
- 未端到端测试 notification panel toggle；需要在 dock 恢复后点击 notification button 验证。

## 清理

- 验证使用的 repo-local `docs/cache` 目录已删除。
