# 桌面环境对比

## 概要

`end-4/dots-hyprland` 是三者中用户可见 shell 产品最完整的参考。Isabel 是最强的 Nix-managed 日用工作站参考。当前 Axiom 已经站在正确架构主线上，但只实现了完整 product-shell surface 的紧凑子集。

推荐方向是：在 Axiom 现有 Nix-native Hyprland + UWSM + Quickshell 架构内，向 `end-4/dots-hyprland` 的能力等价演进；同时用 Isabel 校验工作站可靠性和声明式边界。

## 高层定位

| 维度 | end-4/dots-hyprland | Isabel | 当前 Axiom |
|---|---|---|---|
| 产品身份 | 以 Quickshell 为主产品的自定义 Hyprland 桌面环境。 | Nix-managed 日用桌面，包含 Hyprland、Quickshell 和 polished app/profile integration。 | NixOS 工作站，使用 Hyprland + 本地 Quickshell side dock。 |
| 架构风格 | Mutable dotfiles installer；XDG file sync/copy；distro scripts。 | Nix flake/module/profile system。 | 使用本地 `hey` 约定的 Nix flake/module/host system。 |
| Compositor/session | Hyprland 直接由 session config 启动；上游警告不要选择 UWSM。 | Nix-managed desktop profile 中的 Hyprland。 | Hyprland with UWSM、systemd path integration、greetd command、portals。 |
| Shell | 大型 Quickshell platform，包含 services、panels、settings、sidebars、search、notifications。 | 启用 Quickshell；有产品桌面指导和可见 shell 方向。 | 小型仓库自有 Quickshell dock，包含 launchers、controls、clock、notification count。 |
| 主 UX | Material/dynamic、discoverable、广泛 integrated controls 和 power-user features。 | Polished workstation，重视 coherent theme、rules、app defaults、media/desktop reliability。 | Product-shell first pass：可见 side dock + 外部工具。 |

## 栈对比

| 能力 | end-4/dots-hyprland | Isabel | 当前 Axiom | 缺口 / 采用建议 |
|---|---|---|---|---|
| Monitor/workspace model | 通用默认值 + override files + `nwg-displays` 生成的 monitor/workspace files。 | system profile 中的 declarative device monitor mapping。 | `modules.desktop.hyprland.monitors` 的 Nix option list；Axiom 为 3840x2160@60 scale 1.5。 | 保留 Axiom 的声明式模型；不要让 `nwg-displays` 成为真源。 |
| Hyprland polish | Gaps、blur、animations、gestures、广泛 rules、shell namespaces。 | Rounded/gapped product feel、GUI-friendly rules、direct app bindings。 | Gaps、rounding、animations、app rules、guide shortcut、screenshots、workspace bindings。 | Axiom 已接近；只在有价值处增加 shell IPC 和更丰富 state-aware rules。 |
| Session startup | `exec-once` 启动 Quickshell、hypridle、DBus env、cliphist watchers、EasyEffects。 | Nix-managed session/profile conventions。 | UWSM/greetd + `hyprland-session.target`；Quickshell 作为 systemd user service。 | 保留 Axiom 的 systemd/UWSM ownership。 |
| Quickshell structure | 完整 shell framework，含 families、services、settings、generated state、panels。 | Quickshell 是 desktop profile 一部分；之前任务选择本地 shell 而非导入 `garden`。 | 一个 `shell.qml` 加 `DockButton.qml`。 | 以小 service 扩展 Axiom，而不是导入上游。 |
| Launcher/search | Shell search 支持 apps、web、commands、clipboard、emoji、math、actions、wallpaper commands、scripts；Fuzzel fallback。 | GUI app bindings；launcher 方向在本地证据中没那么深入。 | Dock 和 `Super+Space` 打开 `fuzzel`。 | 逐步添加 shell-owned search；保留 Fuzzel fallback。 |
| Notifications | Quickshell notification server，支持 persistence、grouping、actions、popups、unread state。 | Notification reliability 属于产品桌面预期。 | Quickshell `NotificationServer` 只递增 count；没有 history/center。 | 高优先级缺口。 |
| Quick settings | Inline audio/network/Bluetooth/session controls；部分 KDE fallback tooling。 | NetworkManager/iwd/resolved、BlueZ/Blueman reliability、GUI entry points。 | 外部 `nm-connection-editor`、`blueman-manager`、`pavucontrol`、`wlogout`。 | 先做 shell-native status，再做 controls；保留外部 fallback。 |
| Audio/media OSD | Shell OSD 和 PipeWire stream/device service。 | 研究中强调 media/mpv/OBS/PipeWire polish。 | `hey .osd` 管 volume/brightness；mpv 已有 GPU/Vulkan 配置。 | 把 OSD 接到 Quickshell，并暴露 media/player status。 |
| Wallpaper/theme | Wallpaper-driven Material colors，通过 Matugen 覆盖 shell、Hyprland、Hyprlock、Fuzzel、GTK、KDE、terminal/editor。 | Catppuccin/full-chain theme consistency。 | 静态 autumnal theme 和指定 wallpaper path。 | 决定 dynamic color 是核心还是可选；若采用则声明式实现。 |
| Lock/idle | Quickshell lock surface + Hyprlock fallback；hypridle policy。 | Lock/session reliability 属于 workstation polish。 | Hyprlock package/config generation 和 `hey .lock`；module 中有 idle options。 | 可选项：shell lock UI 可在 controls/notifications 后再做。 |
| Screenshots/recording/OCR | rich bindings：screenshot、swappy、OCR、Google Lens、screen translate、recording、color picker。 | OBS/wlrobs 和 screenshots 是日用桌面验收项。 | `hey .screenshot`、`hey .screencast`、`hyprpicker`、gromit draw。 | 只有明确需要时再加 OCR/translation；当前 screenshot 基础足够。 |
| Clipboard | `wl-paste` watchers、cliphist、shell clipboard history 和 superpaste。 | 本地 Isabel summary 中不是核心。 | 有 `wl-clipboard` 包；shell 没有可见 clipboard history。 | 适合作为 shell search 的第二阶段能力。 |
| Browser/media/chat/gaming | Browser fallback chain；MPRIS media；generic game/window rules。 | Chromium/GPU/Wayland、Discord、OBS、mpv、NVIDIA、Steam 都是一等关注点。 | Zen、Vesktop、Steam/Gamescope/Gamemode/Mangohud、mpv GPU/Vulkan。 | 对 workstation 细节而言，Axiom/Isabel 强于 end-4。 |
| Dependencies | 很广：Quickshell、KDE controls、portals、OCR、screenshot tools、mpvpaper、AI/cloud options。 | 广但由 Nix profiles 管理，面向 workstation。 | 更窄的 Nix-managed packages。 | 按能力采用，不采用 dependency bundle。 |

## 当前 Axiom 强项

- 已经使用 Hyprland、UWSM、portals、greetd 和 Quickshell service ownership。
- 有可见 side dock 和用户 guide，不是隐藏的 shortcut-only workflow。
- 桌面配置保留在仓库内并通过声明式方式链接。
- 有 Axiom-specific workstation packages：Zen、Vesktop、Steam、Thunar、fcitx5-rime、mpv GPU/Vulkan、NVIDIA 相关工具。
- monitor ownership 比上游 `end-4/dots-hyprland` 更清晰。

## 当前 Axiom 相对 end-4 目标状态的缺口

- 没有真正 notification center/history/actions。
- 除了打开 `fuzzel`，没有 shell-owned launcher/search。
- 没有 inline Wi-Fi/Bluetooth/audio device control；只有外部 GUI tools。
- 没有 shell-native OSD 或 media controls。
- 没有 wallpaper/dynamic color pipeline。
- 没有 clipboard history 或 superpaste surface。
- 没有 shell 内 first-run/settings/cheatsheet UI。
- 没有 OCR/screen translation/Google Lens-style capture flows。
- Shell 仍是紧凑 dock，不是 service-oriented desktop environment。

## 重要冲突

- UWSM：上游警告不要使用 UWSM；Axiom 依赖 UWSM。Axiom 应继续保留 UWSM。
- Mutability：上游在用户目录写 generated config/state；Axiom 应先分类 state 并保持声明式边界。
- KDE dependency gravity：上游部分操作假设 KDE controls；采用前 Axiom 应明确是否接受。
- 范围：上游包含 AI/cloud/wallpaper automation features；这些不能在没有 privacy/secrets design 时进入 Axiom。

## 推荐解释

`end-4/dots-hyprland` 应定义目标能力集，而不是定义实现。Axiom 应保持 Nix-native，并按下列顺序增量添加能力：

1. Notification center 和 shell state model。
2. Shell-owned search/action surface，保留 Fuzzel fallback。
3. Audio、network、Bluetooth、media 和 session 的 inline status/quick controls。
4. Quickshell OSD 和更丰富 guide/cheatsheet。
5. 可选 dynamic wallpaper/theme pipeline。
6. Core desktop controls 稳定后，再做可选 OCR/clipboard/translation/AI extras。
