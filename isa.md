# Axiom 主力机体验研究报告：从 isabelroses/dotfiles 吸收什么

> 研究对象：<https://github.com/isabelroses/dotfiles>  
> 本地快照：`/Users/c1/.openclaw/workspace/research/isabelroses-dotfiles`，commit `dcc20d3`  
> 对照对象：`/Users/c1/dotfiles` 当前 `hosts/axiom/default.nix` 与桌面相关模块

## 0. 结论先行

Axiom 当前配置已经有很强的硬件/开发基础：`Ryzen 9950X + RTX 5090`、NVIDIA、Steam、Chrome/Librewolf、fcitx5-rime、音频、Docker、全套开发环境都在。但它现在默认启用的是 `bspwm` / X11：

```nix
desktop.bspwm.enable = true;
```

如果目标是“主力机，使用体验不输 Windows”，我建议不要继续把 X11/bspwm 当主路线，而是把 Axiom 切到现有的 `desktop.hyprland` 路线，并从 Isabel 的配置里吸收这些点：

1. **Wayland-first 桌面栈**：Hyprland + portal + Wayland 环境变量 + 现代截图/剪贴板/屏幕录制工具。
2. **NVIDIA/多媒体体验补齐**：VAAPI、Vulkan、mpv GPU 配置、OBS CUDA/wlrobs、Steam/Gamemode/Gamescope。
3. **系统托盘/控制中心**：短期用你已有 Waybar/Rofi 做稳；长期可参考 Isabel 的 Quickshell 方向做“Windows 快捷设置面板”。
4. **浏览器/通讯软件细节**：Chromium/Chrome Wayland + GPU flags、Discord/视频会议/屏幕共享体验要作为一等公民验证。
5. **桌面 polish**：统一字体、GTK/Qt 主题、默认 MIME、文件管理器、蓝牙/Wi-Fi/音频设备入口。
6. **主力机可靠性**：登录、锁屏、待机/唤醒、屏幕 DPMS、SSH、远程访问、NTFS/双系统兼容、Secure Boot/Windows 共存。

我的判断：**Axiom 要像 Windows 一样“顺手”，主要矛盾不是 NixOS 能不能跑，而是桌面体验链路有没有闭环**。Hyprland 只是窗口管理器；Windows 体验来自一整套“默认入口、控制面板、通知、截图、音频、蓝牙、网络、游戏、屏幕共享”的闭环。

---

## 1. Isabel 的电脑是怎么配置的

### 1.1 仓库结构

Isabel 的 dotfiles 是一个多平台 Nix flake：

- `systems/`：具体机器配置
- `modules/nixos/`：NixOS 系统模块
- `modules/home/`：home-manager 基础模块
- `home/isabel/`：用户级 GUI/CLI/TUI/主题配置
- `docs/`：文档站点

她自己的文档里标注 `amaterasu` 是一台 **NixOS 桌面主机，并且 dual boot Windows 11**。这台机器最适合作为 Axiom 的参考对象。

### 1.2 桌面主机 amaterasu

`systems/amaterasu/default.nix` 的核心设置：

```nix
garden.profiles.graphical.enable = true;
garden.profiles.workstation.enable = true;

garden.device = {
  cpu = "intel";
  gpu = "nvidia";
  monitors = {
    DP-1.refresh-rate = 144;
    DP-2 = { };
  };
  capabilities = {
    tpm = true;
    bluetooth = true;
    yubikey = true;
  };
  keyboard = "us";
};

garden.system.boot = {
  loader = "systemd-boot";
  secureBoot = true;
};
```

用户侧 `systems/amaterasu/users.nix` 开了：

```nix
programs = {
  discord.enable = true;
  ghostty.enable = true;
  chromium.enable = true;
  obs-studio.enable = true;
  fish.enable = true;
  hyprland.enable = true;
  quickshell.enable = true;
};

garden.profiles.media = {
  creation.enable = true;
  streaming.enable = true;
};
```

这说明她主力桌面的核心路线是：

**NixOS + Hyprland + Quickshell + Chromium + Ghostty + Discord + OBS + Catppuccin + NVIDIA + Secure Boot。**

---

## 2. 可直接吸收的设计

### 2.1 Hyprland：不是“极简 WM”，而是完整桌面会话

Isabel 的 Hyprland 配置值得参考的点：

- Declarative monitor mapping：根据 `garden.device.monitors` 自动生成 `monitor=` 与 workspace 分配。
- `systemd.user` 绑定 Hyprland session target。
- 常用入口绑定完整：浏览器、文件管理器、终端、Obsidian、launcher、锁屏、截图。
- 媒体键直接控制 PipeWire / playerctl。
- 特殊 workspace / scratchpad。
- 对 Steam、sharing indicator、Bitwarden、网络连接窗口等常见 GUI 做 window rule。
- 关闭 Hyprland logo/autoreload/splash，提升“产品感”。
- 设置 DPMS 唤醒行为：鼠标/键盘唤醒屏幕。

Axiom 现有 Hyprland 模块其实已经很成熟，而且更贴合 C1 的工作流：

- `config/hypr/hyprland.conf` 已有 modal submap：截图、退出/session、批量窗口管理。
- 已有 screenshot/screencast/screendraw/zoom/osd 等脚本。
- 已有 Waybar、Mako、Hyprlock、Swayidle、Hyprshade、Hyprshot。
- 有 Steam window rules，说明已经考虑游戏窗口兼容。

所以我不建议复制 Isabel 的 Hyprland 配置；更好的做法是：

> **把 Axiom 从 bspwm 切到你自己的 Hyprland 模块，然后吸收 Isabel 的“桌面完整性清单”。**

优先补：

- Axiom 的 monitor 声明，包括主屏、刷新率、缩放、位置。
- Discord / Chrome / Steam / 文件选择器 / 网络管理器 / 蓝牙 / OBS 的 window rules。
- `workspace special` 规则：终端 scratchpad、临时 pad。
- sharing indicator 丢到 special workspace，避免屏幕共享指示器占 workspace。
- 媒体键区分输出音量、输入音量、Spotify/播放器音量。

### 2.2 Quickshell：长期方向，不建议第一阶段强上

Isabel 用 Quickshell 写了一套接近 Windows/macOS 控制中心的东西：

- bar
- quick settings popup
- Bluetooth panel
- PipeWire volume control
- network status
- battery / UPower
- media players
- notifications
- OSD
- systray

这对“不输 Windows”的目标很关键，因为 Windows 的好用很大一部分来自右下角控制中心。

但 Quickshell 的代价也明显：

- QML 自定义代码多，维护成本高。
- 新机器上线阶段，问题排查难度比 Waybar/Rofi/Mako 大。
- Isabel 的实现与她自己的 `garden` 模块体系绑定，不适合直接搬。

建议路线：

- **Phase 1：继续用 Axiom 现有 Waybar + Rofi + Mako**，补齐入口和状态展示。
- **Phase 2：如果 C1 真正在 Axiom 上长期办公，再考虑做一个 C1 版 Quickshell/AGS 控制中心**。

短期要达到 Windows 级顺手，不一定需要 Quickshell；但需要有这些入口：

- Wi-Fi 管理
- 蓝牙设备管理
- 音频输入/输出切换
- 截图/录屏
- 电源菜单
- 锁屏/睡眠/重启
- 通知历史

你现有 Rofi 模块已经有 `wifimenu`、`audiomenu`、`powermenu`、`mountmenu`、`bluetooth` launcher，这部分很适合作为短期主线。

### 2.3 浏览器：Isabel 的 Chromium 配置很有参考价值

Isabel 的 `home/isabel/gui/chromium.nix` 不是简单安装 Chromium，而是做了大量体验/性能/隐私配置：

- `enableWideVine = true`：视频平台 DRM。
- Wayland flags：`--ozone-platform=wayland`、`UseOzonePlatform`。
- GPU flags：`gpu-rasterization`、`oop-rasterization`、`zero-copy`、`--ignore-gpu-blocklist`。
- 磁盘缓存放到 `$XDG_RUNTIME_DIR/chromium-cache`。
- 禁止 first run / default browser nags。
- 预装扩展：uBlock、Bitwarden、SponsorBlock、ff2mpv、Refined GitHub 等。
- native messaging：`ff2mpv`。

Axiom 当前启用：

```nix
browsers = {
  default = "librewolf";
  librewolf.enable = true;
  chrome.enable = true;
};
```

我的建议：

- 保留 Librewolf 作为 privacy/default browser 可以。
- 但主力机必须把 **Chrome/Chromium 作为一等公民**，因为交易、Web3、会议、视频、Google 系生态经常更依赖 Chromium。
- 给 Chrome/Chromium 增加 Wayland/GPU flags。
- 明确配置 Widevine/DRM、桌面 portal、屏幕共享。
- 配 `ff2mpv` 或等价方案，让浏览器视频可以无缝转 mpv。

### 2.4 媒体体验：mpv / OBS / Spotify 的细节值得抄

Isabel 的 mpv 配置非常适合作为“Windows 媒体体验”的参考：

- `gpu-next`
- Linux 下 `gpu-api = vulkan`
- `hwdec = auto-copy`
- `profile = gpu-hq`
- `volume-max = 200`
- SponsorBlock
- modernz UI
- thumbfast 缩略图
- mpv 同时当 image viewer
- 截图目录与模板
- 英/日音轨字幕偏好

Streaming/creation：

- OBS 开 `cudaSupport = true`
- OBS 插件：`wlrobs`、`obs-multi-rtmp`、`obs-move-transition`
- Chatterino
- Gimp/Inkscape

Axiom 当前只启用：

```nix
desktop.media.video.enable = true;
```

建议补强：

- 如果 Axiom 是主力机，media profile 不应只开 video，应有 `watching / creation / streaming / music` 等更清晰分层。
- OBS 必须为 NVIDIA/CUDA/Wayland 做专项验证。
- mpv 建议吸收 Isabel 的 GPU/Vulkan/modern UI 配置。
- 如果 C1 有视频会议/录屏需求，`wlrobs + xdg-desktop-portal-hyprland` 是关键。

### 2.5 音频：PipeWire + EasyEffects 已有，建议加 rnnoise 虚拟麦克风

Isabel 做了一个 `rnnoise` PipeWire filter-chain：生成 `Noise Canceling source`。

这对主力机非常实用：微信、Discord、会议、录屏都能直接选择降噪麦克风。

Axiom 当前已有：

- PipeWire
- rtkit
- EasyEffects
- pavucontrol
- audio/realtime profile

建议：

- 复制思路，不一定复制实现：添加一个 `modules/profiles/hardware/audio/rnnoise.nix` 或集成到 audio profile。
- 让系统默认暴露一个 `Noise Canceling source`。
- 保留 EasyEffects 用于输出/输入高级处理。

### 2.6 NVIDIA：两边都在处理，但 Axiom 需要 5090 专项策略

Isabel 的 NVIDIA 模块：

- `services.xserver.videoDrivers = [ "nvidia" ]`
- `nvidia_drm.fbdev=1`
- `LIBVA_DRIVER_NAME=nvidia`
- `WLR_DRM_DEVICES` 默认 `/dev/dri/card1`
- `nvidia-vaapi-driver`
- Vulkan 工具链
- bleeding-edge driver branch
- 默认不开 open kernel module

C1 当前 NVIDIA 模块：

- `hardware.graphics.enable = true; enable32Bit = true`
- `hardware.nvidia.open = mkDefault true`
- `modesetting.enable = true`
- `package = nvidiaPackages.beta`
- Wayland 下设置 `LIBVA_DRIVER_NAME=nvidia`、`WLR_NO_HARDWARE_CURSORS=1`、`GBM_BACKEND=nvidia-drm`、`__GLX_VENDOR_LIBRARY_NAME=nvidia`
- CUDA toolkit

RTX 5090 是新卡，建议 Axiom 做成“新 NVIDIA 主力机 profile”，关注：

- driver 用 beta / production / latest 的实际兼容性，不要教条固定。
- open kernel module 对 50 系可能是推荐方向，但必须实机验证 suspend、Wayland、CUDA、游戏。
- Chrome/Discord/Electron 屏幕共享、硬解、VAAPI 要实际测。
- Steam/Proton + Gamescope + Gamemode 要实际测。
- `WLR_NO_HARDWARE_CURSORS` / `GBM_BACKEND` 这类变量要按实机现象保守启用，避免为了解一个问题制造另一个问题。

### 2.7 主题与字体：统一性会显著提升“不是拼装 Linux”的感受

Isabel 做了完整 Catppuccin：

- GTK theme
- Qt/Kvantum
- pointer cursor
- terminal theme
- mpv/spotify/discord 风格
- fonts：Berkeley Mono / Maple Mono / Symbols Nerd Font
- MIME defaults：浏览器、代码、媒体、图片、文件管理器

Axiom 当前主题是 `autumnal`，已有主题体系。建议不换审美方向，但吸收她的“全链路覆盖”原则：

- GTK/Qt 统一深色主题。
- cursor theme 在 Hyprland/GTK/XWayland 下都一致。
- terminal/editor/browser/file manager 视觉统一。
- 默认 MIME 明确：目录、图片、视频、PDF、URL、文本文件。
- 中文字体 fallback 要专项补齐：Noto CJK / 思源黑体 / emoji / Nerd Font。

### 2.8 蓝牙、Wi-Fi、文件管理器：不要小看这些 Windows 级细节

Isabel 对蓝牙和网络做得比较完整：

- Bluetooth：BlueZ、禁用 SAP、`JustWorksRepairing=always`、`MultiProfile=multiple`、Blueman。
- NetworkManager：iwd backend、systemd-resolved、Wi-Fi 扫描随机 MAC、忽略 docker/tailscale/bridge/waydroid 等虚拟接口。
- GUI 包：`networkmanagerapplet` 提供 `nm-connection-editor`。
- 文件管理器：Cosmic Files，并把 `inode/directory` 默认给它。

Axiom 当前有 bluetooth/wifi profile，建议确认：

- 是否有稳定 GUI 管理入口：Blueman / rofi-bluetooth / nm-connection-editor。
- 蓝牙耳机多 profile 切换是否正常。
- Wi-Fi + 有线 + Tailscale/Docker/桥接时，NetworkManager 不要乱管虚拟接口。
- 文件管理器建议明确选择一个：Thunar / Cosmic Files / Nautilus / Dolphin，不要只靠终端。

---

## 3. 不建议直接照搬的东西

1. **Quickshell 整套 QML**  
   很漂亮，但维护成本高。第一阶段用 Waybar/Rofi/Mako 更稳。

2. **Discord Moonlight/OpenAsar 全套 patch**  
   Isabel 的 Discord 配置很强，但这类客户端 patch 有兼容/账号/ToS 风险。Axiom 可以先保证官方 Discord/vesktop/legcord 的屏幕共享、托盘、输入法、通知稳定，再决定是否 patch。

3. **她的 flake/module 架构**  
   结构精致，但 C1 dotfiles 已经有自己的 `hey` 模块体系。不要为借几个桌面体验点引入架构迁移。

4. **Secure Boot 立即开启**  
   如果 Axiom 要和 Windows/游戏反作弊共存，Secure Boot 值得做；但它会增加安装/恢复复杂度。建议作为主力机稳定后的第二阶段。

---

## 4. Axiom 当前状态判断

`hosts/axiom/default.nix` 已经有这些优势：

- 主机命名与硬件 profile 已定。
- `gpu/nvidia`、`cpu/amd`、`ssd`、`bluetooth`、`wifi`、`audio/realtime` 已启用。
- Steam 已启用。
- Chrome + Librewolf 已启用。
- fcitx5-rime 已启用。
- Dev 环境完整：Node/Deno/Rust/Python/Java。
- editor/shell/docker/ssh/calibre 都有。
- `ntfs` 文件系统支持已加。

主要短板：

1. **仍启用 `bspwm`，不是现代主力桌面的最优路线。**
2. **Axiom 没有显示器布局/刷新率声明。** 5090 主力机大概率会接高刷/多屏。
3. **桌面体验入口不够显式**：蓝牙、Wi-Fi、音频设备、截图、录屏、通知历史、电源菜单需要验收。
4. **NVIDIA 5090 实机变量未验证**：open module、beta driver、Wayland、VAAPI、CUDA、sleep/resume 都要测。
5. **浏览器/视频会议体验还没被当作验收项**：这是 Windows 替代成败的核心之一。

---

## 5. 推荐实施路线

### Phase 1：把 Axiom 变成可日用主力机

目标：一天内能开始用，不被低级桌面问题打断。

建议改动：

```nix
desktop = {
  # bspwm.enable = false;
  hyprland.enable = true;

  apps = {
    rofi.enable = true;
    steam.enable = true;
  };

  browsers = {
    default = "chrome"; # 或保留 librewolf，但 chrome 必须一等公民
    librewolf.enable = true;
    chrome.enable = true;
  };
};
```

同时补：

- Axiom Hyprland monitor 配置。
- Waybar 主屏输出。
- Rofi power/audio/wifi/bluetooth/mount launcher 确认可用。
- Mako notification + dismiss/history 快捷键。
- Screenshot：区域、窗口、全屏、编辑、复制到剪贴板。
- Screencast：窗口/屏幕录制。
- File manager 默认应用。
- Chrome/Chromium Wayland/GPU flags。
- Fcitx5/Rime 在 Chrome、微信/聊天软件、终端、Electron 中验证。

### Phase 2：补齐 Windows 级体验

目标：游戏、会议、媒体、通讯都稳定。

建议补：

- Steam：Gamemode/Gamescope/Mangohud/Proton-GE 路线。
- OBS：CUDA + wlrobs + portal 验证。
- mpv：吸收 Isabel 的 GPU/Vulkan/modernz/thumbfast/SponsorBlock 配置。
- PipeWire：rnnoise 虚拟降噪麦克风。
- Bluetooth：耳机多 profile，手柄，键鼠。
- NetworkManager：iwd backend + 忽略 docker/tailscale bridge。
- xdg MIME defaults：目录、图片、视频、PDF、URL。
- GTK/Qt/cursor/font 统一。

### Phase 3：主力机 polish

目标：不是“能用”，而是“愿意一直用”。

可选方向：

- 做 C1 版 Quickshell/AGS 控制中心。
- Secure Boot + Windows dual boot 完整文档。
- Declarative backup：home、浏览器 profile、SSH/GPG、交易相关配置。
- NVIDIA 实机调参 profile：`gpu/nvidia/blackwell` 或 `gpu/nvidia/new`。
- Axiom 专门的 test checklist：每次大升级后验证桌面核心路径。

---

## 6. Axiom 验收清单

如果目标是不输 Windows，我建议用下面这张清单验收，而不是只看 `nixos-rebuild` 成功。

### 桌面/显示

- [ ] 进入桌面无需手工命令。
- [ ] 主屏/副屏位置正确。
- [ ] 高刷新率生效。
- [ ] 缩放正常。
- [ ] XWayland 应用不会随机跑到错误屏幕。
- [ ] 锁屏/解锁可靠。
- [ ] 待机/唤醒后桌面、音频、网络、NVIDIA 正常。

### 输入法

- [ ] Rime 在 Chrome/Librewolf 可用。
- [ ] Rime 在 Electron/Discord/微信类应用可用。
- [ ] Rime 在终端/Emacs/VSCode 可用。
- [ ] 中英文切换快捷键顺手。

### 浏览器/会议

- [ ] Chrome Wayland native。
- [ ] 硬件加速开启。
- [ ] Web3 钱包/交易后台正常。
- [ ] Google Meet/Zoom/Discord 屏幕共享正常。
- [ ] 摄像头/麦克风/降噪设备可选。
- [ ] DRM 视频可播放。

### 音频/蓝牙

- [ ] 蓝牙耳机连接稳定。
- [ ] A2DP/HFP 切换可控。
- [ ] 默认输出/输入可从 GUI 切换。
- [ ] 媒体键可控制音量/播放。
- [ ] rnnoise 降噪麦克风可用。

### 游戏/图形

- [ ] Steam 正常启动。
- [ ] Proton 游戏可运行。
- [ ] Gamescope/Gamemode 可用。
- [ ] Mangohud 可用。
- [ ] NVIDIA driver/CUDA/nvidia-smi 正常。
- [ ] Vulkan/VAAPI 基本测试通过。

### 日常工具

- [ ] 截图：区域、窗口、全屏。
- [ ] 截图可编辑/复制。
- [ ] 录屏可用。
- [ ] 文件管理器可打开目录/挂载盘。
- [ ] 通知中心/历史/免打扰可控。
- [ ] Wi-Fi/蓝牙/音频/电源菜单有 GUI/launcher 入口。

---

## 7. 具体落地建议列表

按优先级排序：

1. **Axiom 改用 Hyprland，而不是 bspwm。**  
   这是最大收益点。你已有 Hyprland 模块，不需要从零写。

2. **给 Axiom 加 monitor 配置。**  
   Isabel 的 `garden.device.monitors` 思路可以吸收：声明输出、刷新率、scale、workspace 映射。

3. **补 Chrome/Chromium Wayland/GPU flags。**  
   吸收 Isabel 的 Chromium 配置，但保留 C1 自己的 Chrome/Librewolf 模块风格。

4. **补 mpv 高质量配置。**  
   `gpu-next + vulkan + hwdec + modern UI + SponsorBlock + thumbfast`，这部分很值。

5. **补 rnnoise 虚拟麦克风。**  
   会议/聊天/录屏体验提升明显。

6. **明确文件管理器和 MIME defaults。**  
   不要让主力机在“打开目录/图片/PDF/视频”这种小事上掉链子。

7. **Steam/Gamemode/Gamescope/Mangohud 实机验证。**  
   Axiom 硬件很强，不让 Linux 图形栈拖后腿。

8. **Waybar/Rofi 做控制中心替代品。**  
   先别急着搬 Quickshell，把现有 Rofi 菜单打磨到足够顺手。

9. **NVIDIA 5090 单独建兼容性 checklist。**  
   尤其是 open module、beta driver、sleep/resume、screen sharing、VAAPI、CUDA。

10. **稳定后再做 Secure Boot / 双系统 polish。**  
   Isabel 的 amaterasu 是 dual boot Windows 11 + Secure Boot，这方向对主力机有价值，但不应阻塞第一阶段日用。

---

## 8. 推荐的最终形态

我建议 Axiom 的定位是：

> **C1 的高性能交易/开发/娱乐主力工作站：NixOS + Hyprland + NVIDIA Blackwell + Chrome/Librewolf + Steam/OBS/mpv + 完整中文输入 + 稳定远程访问。**

技术路线：

- 桌面：Hyprland
- 状态栏：Waybar，后续可 Quickshell
- Launcher：Rofi，后续可 Vicinae/Walker
- 通知：Mako 或 Dunst，但 Wayland 下建议 Mako
- 浏览器：Chrome 主力 + Librewolf 隐私备用
- 终端：foot 当前可继续；也可评估 Ghostty/WezTerm
- 媒体：mpv 强配置
- 游戏：Steam + Proton + Gamescope + Gamemode + Mangohud
- 音频：PipeWire + EasyEffects + rnnoise
- 输入法：fcitx5-rime
- 文件管理器：明确选择一个 GUI 文件管理器
- 主题：沿用 autumnal，但补齐 GTK/Qt/cursor/font/MIME

一句话：**不要把 Axiom 做成“装了 NixOS 的服务器 + 一个 WM”，要做成“我愿意每天坐下来打开它的主力桌面产品”。**

这也是 Isabel 配置最值得吸收的地方：她不是只配置包，而是在配置一台“真的每天用的电脑”。

