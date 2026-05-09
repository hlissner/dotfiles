# 研究记录

## 范围

这是 `.legion/tasks/dots-hyprland-desktop-rfc/` 的 design-only 研究。它把 `end-4/dots-hyprland` 作为上游桌面产品参考，把 Isabel 作为已研究过的产品基线，把当前 Axiom 作为本地实现基线。

## 来源

- 上游研究 subagent 在 `/tmp/opencode/dots-hyprland` 检查了 `https://github.com/end-4/dots-hyprland`。
- 上游快照：`bebf66da89cd2afa4738da47fb3a0a9fa5af7035`，时间 `2026-05-09T00:10:09+08:00`，commit 标题 `Use packages from end-4/ii-package-builds for fedora (#3288)`。
- 当前 Axiom host：`hosts/axiom/default.nix`。
- 当前 Axiom Hyprland 模块/配置：`modules/desktop/hyprland.nix`、`config/hypr/hyprland.conf`。
- 当前 Axiom shell：`modules/desktop/quickshell.nix`、`config/quickshell/axiom-shell/shell.qml`、`config/quickshell/axiom-shell/DockButton.qml`。
- 当前 Axiom guide：`config/axiom-desktop/guide.md`。
- Isabel 证据：`isa.md` 和 `.legion/tasks/dotfiles-quickshell-product-desktop/docs/{research.md,rfc.md}`。

## 上游概要

`end-4/dots-hyprland` 主要不是 NixOS module 设计，而是一个以 mutable dotfiles/install scripts 为基础的仓库；它的产品中心是一套运行在 Hyprland 之上的大型 Quickshell 桌面 shell。

subagent 报告中的重要上游路径：

- `dots/.config/hypr/hyprland.conf`：source 默认 Hyprland 片段和用户 overrides。
- `dots/.config/hypr/hyprland/execs.conf`：启动 Quickshell、hypridle、DBus 环境导出、EasyEffects、clipboard watchers 和 cursor setup。
- `dots/.config/hypr/hyprland/keybinds.conf`：绑定 Quickshell global search、utility actions、screenshots/OCR/recording、windows/workspaces、session actions、media keys 和 app launchers。
- `dots/.config/hypr/hyprland/rules.conf`：处理 dialogs、PiP、screen sharing indicators、games、JetBrains focus workarounds 和 Quickshell layer namespaces。
- `dots/.config/quickshell/ii/shell.qml`：初始化 shell、startup services、panel families、first-run behavior、wallpapers、clipboard 和 update services。
- `dots/.config/quickshell/ii/panelFamilies/IllogicalImpulseFamily.qml`：组合主 shell：bar、background、cheatsheet、dock、lock、media controls、notification popup、OSD、overview、sidebars、overlay、vertical bar、wallpaper selector 等。
- `dots/.config/quickshell/ii/panelFamilies/WaffleFamily.qml`：提供类似 Windows 的 alternate family，包含 action center、bar、task view、start menu、notification center、OSD、lock 和 session screen。
- `dots/.config/quickshell/ii/services/*.qml`：包含 audio、Bluetooth、clipboard history、launcher/search、network、notifications、tray、wallpaper、weather、updates 和 Hyprland state 等 shell services。
- `dots/.config/matugen/config.toml`：把动态颜色映射到 Quickshell、Hyprland、Hyprlock、Fuzzel、GTK、KDE 和 wallpaper outputs。
- `sdata/deps-info.md`：记录依赖分组，包括 portals、KDE controls、screenshot/OCR tools 和 shell dependencies。

## 当前 Axiom 概要

Axiom 已经具备相同核心栈，但实现更小：

- `hosts/axiom/default.nix` 启用 Hyprland、3840x2160@60 且 scale 1.5 的 monitor、Discord/Vesktop、Steam、Thunar、fcitx5-rime/pinyin、Zen、foot 和 video media。
- `modules/desktop/hyprland.nix` 启用 Hyprland with UWSM、systemd path integration、Hyprland portal + GTK fallback，并通过 `uwsm start` 由 greetd 启动。
- `modules/desktop/quickshell.nix` 以 `quickshell.service` 运行仓库自有 Quickshell，并把 `config/quickshell/axiom-shell` 链接进用户配置。
- `config/quickshell/axiom-shell/shell.qml` 是紧凑的可见侧边 dock，包含 workspace buttons、app launchers、外部 GUI control buttons、notification count、clock、screenshot、recording、lock 和 power actions。
- `config/hypr/hyprland.conf` 已有产品向 Hyprland polish：gaps、rounded corners、guide shortcut、app bindings、screenshots/recording、workspace bindings、media keys 和 GUI control keybinds。
- `config/axiom-desktop/guide.md` 直接说明产品目标：Axiom 应先像一台完整个人电脑，其次才是 tiling WM。

## Isabel 概要

Isabel 基线仍然适合作为产品质量参考，尤其适合 Nix 管理的日用桌面：

- Isabel 的已记录桌面路线是 NixOS + Hyprland + Quickshell + Chromium + Ghostty + Discord + OBS + Catppuccin + NVIDIA + Secure Boot。
- 她的系统模型使用声明式 device capabilities、monitors 和 profiles。
- Isabel 研究识别出的可吸收面包括 polished Hyprland rules、GUI bindings、NetworkManager/iwd/resolved、BlueZ reliability、Chromium/GPU/Wayland 细节、mpv/OBS media polish，以及 theme/MIME/font consistency。
- 之前的 Axiom Quickshell product task 明确避免导入 Isabel 的完整 `garden` framework，而是实现本地 shell。

## 关键发现

- `end-4/dots-hyprland` 在 shell 广度上领先当前 Axiom：notifications、launcher/search、action center、quick toggles、wallpaper manager、dynamic colors、OSD、sidebars、lock UI、clipboard history、OCR/screen translation 和 first-run/settings flows。
- Axiom 在 NixOS 集成上领先 `end-4/dots-hyprland`：UWSM/greetd/systemd service ownership、声明式 host/module 边界，以及通过 Nix options 管理 monitor。
- Isabel 在架构上比 `end-4/dots-hyprland` 更接近 Axiom，因为二者都是 Nix-managed workstation configuration；但 `end-4/dots-hyprland` 是更丰富的 shell-product reference。
- 正确目标是功能等价和产品模型吸收，而不是字面迁移代码。

## 高价值采用点

- 把 Axiom 的 Quickshell 拆成小型 service surfaces：notifications、launcher/search、audio、network、Bluetooth、wallpaper/theme、Hyprland state 和 session actions。
- 添加真正的 notification center：persistence、grouping、actions、unread state 和 conflict handling。
- 用 shell-owned search surface 替代当前只打开 `fuzzel` 的 launcher 路径，同时保留 `fuzzel` fallback。
- 添加 Wi-Fi、Bluetooth、audio devices/streams、media 和 power 的 inline quick controls，同时保留外部工具 fallback。
- 把 wallpaper 和 dynamic color 作为产品能力考虑，但通过受控的 Nix-friendly generated files 实现，而不是复制 mutable installer scripts。
- 添加 shell-native OSD for volume/brightness，并在可行时把现有 `hey .osd` 行为接入可见 shell state。
- 把 guide 扩展成 shell 内 cheatsheet/onboarding surface。
- 可考虑更丰富的 screenshot/recording/OCR workflows，但 AI/cloud 和 booru/wallpaper automation 必须保持明确 opt-in scope。

## 不可移植或高风险的上游假设

- 上游 installer 会把 mutable files 复制到 XDG locations；Axiom 应继续通过 Nix/Home Manager 风格机制链接/生成仓库自有配置。
- 上游明确警告不要使用 UWSM，而 Axiom 有意使用 UWSM。不能复制 session 假设。
- KDE-heavy controls，例如 `kcmshell6`、`plasma-systemmonitor`、Dolphin 和 System Settings，除非明确选择，否则可能过重或风格不一致。
- Arch/Fedora/Gentoo installer logic 和 package-manager prompts 不应进入本 NixOS 仓库。
- 上游会写入 `~/.config/illogical-impulse`、`~/.local/state`、cache directories 和 `/tmp` 等用户偏好/生成文件；Axiom 采用类似行为前必须先给 state 分类。
- AI/cloud features 引入 secrets、privacy、network dependency 和 scope 风险。

## 未决问题

- Axiom 是否应长期保留当前 side dock 作为主形态，还是将来支持类似 `ii` / `waffle` 的多 shell family。
- dynamic colors 是否应成为 Axiom 视觉身份的核心，还是作为现有 autumnal theme 之上的可选模式。
- inline Wi-Fi/Bluetooth/audio controls 应依赖 KDE/Qt control modules、GTK tools，还是 shell-native DBus/service integrations。
