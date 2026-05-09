# llm-wiki：end-4/dots-hyprland 桌面配置

## 当前快照

- 仓库：`https://github.com/end-4/dots-hyprland`
- subagent 检查快照：`bebf66da89cd2afa4738da47fb3a0a9fa5af7035`
- 时间：`2026-05-09T00:10:09+08:00`
- 性质：mutable dotfiles + installer，核心是一套自定义 Hyprland + Quickshell 桌面环境。

## 心智模型

这个仓库最好理解为一个构建在 Hyprland 之上的自定义桌面环境，而不是一个极简 WM 配置。Hyprland 提供 compositor，但大多数用户可见产品面由 Quickshell 拥有：panels、search、notifications、OSD、media controls、sidebars、lock UI、wallpaper selection、settings、action center 和 visual identity。

该仓库优化的是 polished personal-computer experience：

- 用可见 controls 降低纯 shortcut 记忆负担；
- 以 wallpaper 驱动 Material/dynamic theming；
- 集成 notifications、media、search、quick toggles 和 session actions；
- 提供 OCR、screen translation、clipboard history、music recognition 和 rich screenshot flows 等 power-user utilities；
- Quickshell 不可用时保留 fallback。

## 安装与运行时假设

- 主 installer 命令：`setup`。
- 配置会被复制或同步到用户 home 下的 XDG directories。
- 支持 Arch、Fedora、Gentoo，以及 experimental Nix/Home Manager dependency/install 路线。
- experimental Nix 路线不等同于成熟的 NixOS module 架构。
- 运行时状态是 mutable 的，位于 `~/.config/illogical-impulse/config.json`、`~/.local/state/quickshell`、`~/.cache/quickshell`、`/tmp/quickshell` 等 XDG config/state/cache 路径。
- installer 警告不要通过 UWSM 启动 Hyprland，这与 Axiom 当前 UWSM 设计冲突。

## 顶层配置地图

| 路径 | 作用 |
|---|---|
| `setup` | install、dependency install、updates、uninstall、checks、virtual monitor helpers 的 installer/router。 |
| `sdata/` | Installer data、distro dependency definitions、setup flows、update/uninstall/check logic。 |
| `sdata/deps-info.md` | shell、portals、screenshots、OCR、KDE controls 和其他功能的依赖说明。 |
| `dots/` | 准备写入 XDG config/data destinations 的文件。 |
| `dots/.config/hypr/` | Hyprland、Hypridle、Hyprlock、monitors/workspaces、default/custom source layering。 |
| `dots/.config/quickshell/ii/` | 主 Quickshell 桌面环境。 |
| `dots/.config/matugen/` | shell、Hyprland、Hyprlock、Fuzzel、GTK、KDE 和 wallpaper outputs 的 dynamic color templates。 |
| `dots/.config/fuzzel/` | Fuzzel fallback launcher theme/config。 |
| `dots-extra/` | 额外 setup payloads、distro/font/input extras 和 experimental Nix support。 |

## Hyprland 层

重要文件：

- `dots/.config/hypr/hyprland.conf`：入口；source 默认 fragments 和用户 overrides。
- `dots/.config/hypr/hyprland/variables.conf`：app launch variables 和 Quickshell config name。
- `dots/.config/hypr/hyprland/execs.conf`：session startup，包含 geoclue、Quickshell、video wallpaper restore、keyring、hypridle、DBus env、EasyEffects、clipboard watchers 和 cursor setup。
- `dots/.config/hypr/hyprland/general.conf`：monitor default、gestures、gaps、border、blur、animations、input、cursor、XWayland behavior。
- `dots/.config/hypr/hyprland/keybinds.conf`：shell globals、screenshots/OCR/recording、utilities、windows/workspaces、session、media 和 app launchers。
- `dots/.config/hypr/hyprland/rules.conf`：dialogs、PiP、sharing indicators、games、JetBrains focus workaround 和 Quickshell namespaces 的 app/window/layer rules。
- `dots/.config/hypr/monitors.conf` 和 `workspaces.conf`：预留给 `nwg-displays` 覆盖的 placeholder files。
- `dots/.config/hypr/hypridle.conf`：lock、DPMS 和 suspend timeouts。
- `dots/.config/hypr/hyprlock.conf`：fallback lock screen。

默认 monitor 行为刻意保持通用：`monitor=,preferred,auto,1`。monitor/workspace customization 交给 override files 或 `nwg-displays`，而不是通过 Nix host model 强声明。

## Quickshell 层

主 shell 入口：

- `dots/.config/quickshell/ii/shell.qml`：初始化 startup services 并选择 panel families。

Panel families：

- `panelFamilies/IllogicalImpulseFamily.qml`：主 shell，包含 bar、background、cheatsheet、dock、lock、media controls、notification popup、OSD、OSK、overview、polkit、region selector、screen corners、translator、session screen、sidebars、overlay、vertical bar 和 wallpaper selector。
- `panelFamilies/WaffleFamily.qml`：类似 Windows 的 alternate shell，包含 action center、bar、task view、start menu、notification center、OSD、lock 和 session screen。

公共基础设施：

- `modules/common/Config.qml`：mutable shell configuration schema。
- `modules/common/Directories.qml`：XDG paths、generated paths、cache/state paths、cleanup/init behavior。
- `modules/common/Appearance.qml`：Material 3 color tokens、wallpaper quantization、transparency 和 visual constants。

Service layer：

- `services/Notifications.qml`：notification server，支持 persistent storage、grouping、actions、unread count 和 popups。
- `services/LauncherSearch.qml`：app/web/shell/clipboard/emoji/math/action/wallpaper/user-script search。
- `services/Audio.qml`：PipeWire sink/source/devices/app-stream state 和 controls。
- `services/Network.qml`：通过 `nmcli` 实现 Wi-Fi/network scan/connect/disconnect/password/captive-portal flows。
- `services/BluetoothStatus.qml`：Quickshell Bluetooth state。
- `services/Wallpapers.qml`：wallpaper browsing 和 apply service。
- 其他 services 覆盖 Hyprland data/config/keybinds、tray、weather、updates、AI、cliphist 和相关 shell state。

## 启动器与搜索

主 launcher/search 由 shell 拥有，并从 Hyprland bindings 触发。它支持：

- application search；
- web search；
- shell commands；
- clipboard history 和 superpaste-style actions；
- emoji；
- 通过 `qalc` 做 calculator/math；
- action prefixes；
- wallpaper commands；
- 来自本地 action directory 的 user scripts。

`fuzzel` 仍作为 fallback launcher，并接收生成的 theme colors。

## 通知

Quickshell 作为 notification server。它支持 persistence、grouping、unread state、actions、popups、timeout policy，并检测与其他 notification daemons 的冲突。

这与最小 notification counter 有本质区别：notifications 是一等 shell data model。

## OSD、锁屏、空闲与会话 UX

- OSD 是 shell panel，用于 volume/brightness 等反馈。
- `hypridle` 在 idle 后锁屏，再关闭 DPMS，并可在更长 timeout 后 suspend。
- Lock 优先使用 Quickshell lock surface，fallback 到 Hyprlock。
- Session 和 power actions 属于 shell surface。

## 壁纸与动态主题

Wallpaper 是视觉真源之一：

- `scripts/colors/switchwall.sh` 切换 wallpaper、生成颜色、更新 app/shell themes、处理 video wallpaper，并桥接到 KDE/GTK/terminal/editor surfaces。
- `matugen/config.toml` 把生成颜色映射到 Quickshell、Hyprland、Hyprlock、Fuzzel、GTK、KDE 和 wallpaper-path outputs。
- Quickshell `Appearance.qml` 暴露 Material 3 tokens 和 wallpaper-derived color behavior。

采用备注：产品思路有价值，但 mutable shell script 不应直接复制到 Axiom。

## 控制与日常桌面入口

集成 controls 包括：

- 通过 shell service over `nmcli` 管理 Wi-Fi/network；
- 通过 Quickshell Bluetooth integration 加 KDE config fallback 管理 Bluetooth；
- PipeWire audio devices、streams、sink/source selection、mute 和 volume protection；
- 通过 MPRIS/playerctl surfaces 管理 media controls；
- system/session/power UI；
- screenshot、OCR、Google Lens、region recording、full-screen recording 和 color picker flows；
- text/image 的 clipboard history watchers。

部分 controls 假设存在 KDE 或 Plasma 工具，例如 `kcmshell6`、`plasma-systemmonitor`、Dolphin 或 System Settings。

## 应用与窗口规则

Rules 强调桌面产品行为：

- float 和 center dialogs；
- pin/float PiP；
- 处理 screen sharing indicators；
- 对 games 应用 tearing/immediate rules；
- workaround JetBrains focus behavior；
- 为 Quickshell namespaces 定义 layer rules。

Application variables 包含 terminal、file manager、browser、code editor、office suite、text editor、volume mixer、settings app 和 task manager 的 fallback chains。Browser fallback 优先 Chrome，其次 Zen，再到 Firefox-like options。

## 产品强项

- 非常完整的 Quickshell service architecture。
- 用户可见 shell 很丰富，不只是 thin bar。
- 强 dynamic theme pipeline。
- 深度 search/action surface。
- First-run、settings、cheatsheet 和 discoverability mechanisms。
- screenshot、OCR、clipboard、media、AI、wallpapers、notifications 和 quick settings 的功能广度。

## 对 Axiom 的可移植限制

- Mutable installer model 与 Axiom 的 Nix-native architecture 冲突。
- UWSM warning 与 Axiom session model 冲突。
- KDE-heavy dependencies 可能不符合 Axiom 目标栈。
- AI/cloud integrations 需要明确 privacy 和 secrets policy。
- 字面导入 Quickshell 会压垮 Axiom 当前紧凑 shell 架构。
- Generated mutable state 采用前需要清晰 Nix boundary。

## 最佳使用方式

把该仓库作为 capability map：

- notification center；
- action/search surface；
- quick settings 和 inline device controls；
- OSD；
- wallpaper/dynamic color pipeline；
- shell settings/onboarding；
- 带 fallback 的 resilient Hyprland-to-shell IPC；
- rich screenshot/recording/OCR workflows。

不要把它作为整体导入源。
