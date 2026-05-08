# Axiom 主力机体验研究报告：从 hlissner/dotfiles 最新上游吸收什么

> 研究对象：<https://github.com/hlissner/dotfiles>  
> 上游快照：`/tmp/opencode/hlissner-dotfiles.ZqBHWc`，commit `1b4383a`  
> 本地对照：`/home/c1/dotfiles`，local HEAD `3c1000e8`，共同祖先 `d97400cd`  
> 本报告前提：**不考虑向后兼容**。旧 X11/bspwm、旧服务模块、旧媒体栈、旧主题链路都可以直接删除或重写。

## 0. 结论先行

如果不考虑向后兼容，Axiom 应该直接从“继承老 dotfiles 的一台机器”收敛成一条新的主力桌面路线：

**NixOS + Hyprland + RTX 5090 + Steam/Proton/Gamescope/Umu + Chrome/Librewolf + PDF/Office/Flatpak 兜底 + 明确 monitor/Wayland/NVIDIA 验收。**

上游最新变化已经给出很明确的方向：

1. **删除 X11/bspwm 路线。** 上游已经移除 `bspwm`、`sxhkd`、Polybar、X11 主题残留。本地不需要再兼容 `desktop.type = "x11"`。
2. **Hyprland 成为唯一桌面会话。** Axiom 应直接启用 `desktop.hyprland`，并补 monitor、高刷、workspace、Steam/game rules。
3. **把桌面模块从“可选兼容层”改成“Wayland-only 产品”。** Rofi 用 `rofi-wayland`，通知用 Mako 或 DMS 二选一，截图/录屏只保留 Wayland 工具链。
4. **游戏栈直接升级。** Steam 启用 `gamescopeSession`，加入 `umu-launcher`，保留 `gamemode` 和 `mangohud`，Steam 游戏固定到专用 workspace。
5. **工作站 sysctl 直接吸收。** `vm.max_map_count`、`split_lock_mitigate`、`tcp_fin_timeout`、`sched_cfs_bandwidth_slice_us` 都适合 Axiom。
6. **补齐 Windows 替代基础应用。** PDF、LibreOffice、Lutris、Flatpak、Thunar/MIME defaults 这些不应再是可选边缘项。
7. **删除或退役本地不再服务 Axiom 的旧模块。** `bspwm`、`dunst`、`swayidle/hypridle` 双实现、旧 Spotify/ncmpcpp 方向、旧 X11 theme 分支，都可以作为清理目标。

我的判断：**这次不要做“兼容旧配置的渐进吸收”，而要做一次桌面路线收敛。** Axiom 是新主力机，不应该背着旧 X11/服务器/播放器/主题链路跑。

---

## 1. hlissner 最新上游发生了什么

共同祖先是 `d97400cd`。上游到 `1b4383a` 的关键变化：

- 移除 X11/bspwm/sxhkd/ncmpcpp/Waybar/Dunst/多种旧服务模块。
- Hyprland 路线改成 `UWSM + greetd + dms-shell + Quickshell + Matugen`。
- `flake.nix` 跟 `nixos-unstable`，新增 `quickshell` input。
- `default.nix` 默认 kernel 改为 `linux_xanmod_latest`。
- Steam 模块新增 `gamescopeSession.enable` 和 `umu-launcher`。
- 新增 `desktop.apps.libreoffice`、`desktop.apps.lutris`、`desktop.media.pdf`、`services.flatpak`。
- workstation profile 增加游戏/桌面负载 sysctl。
- Bluetooth profile 增加 `ControllerMode = "bredr"` 与 `ReconnectAttempts = 0`。
- `xdg.nix` 的 SSH wrapper 更保守：尊重显式 `ssh -F` 和 `ssh-copy-id -i`。
- 音乐栈从 ncmpcpp/MPD 迁到 `feishin + beets + picard + r128gain + flac/cue scripts`。

这不是小修小补，而是上游在主动砍旧路线、收敛桌面产品形态。

---

## 2. 可直接吸收的设计

### 2.1 砍掉 bspwm/X11 兼容层

本地 Axiom 现在还是：

```nix
desktop.bspwm.enable = true;
```

如果不考虑向后兼容，应该直接改成：

```nix
desktop = {
  hyprland = {
    enable = true;
    monitors = [
      # 按实机 hyprctl monitors 填写
    ];
  };
  apps.rofi.enable = true;
  apps.thunar.enable = true;
  apps.steam.enable = true;
  term.foot.enable = true;
};
```

同时删除或退役：

- `modules/desktop/bspwm.nix`
- `modules/themes/autumnal/bspwm.nix`
- `config/bspwm/**`
- `config/sxhkd/**`
- `modules/services/dunst.nix`
- `modules/themes/default.nix` 里 X11 分支
- `desktop.type == "x11"` 相关分支

这样做的收益：

- 桌面逻辑少一半。
- 主题、通知、截图、launcher 不再需要同时照顾 X11/Wayland。
- Axiom 的验收只围绕 Wayland/NVIDIA/Hyprland 展开。

### 2.2 Hyprland：吸收上游现代会话管理

上游 `modules/desktop/hyprland.nix` 的关键点：

```nix
programs.hyprland = {
  enable = true;
  withUWSM = true;
  systemd.setPath.enable = true;
};

services.greetd.settings.default_session.command =
  "uwsm start -eD Hyprland hyprland.desktop";
```

建议本地直接采用 `UWSM`，不要继续维护手写 `hyprland-session.target` wrapper。既然不考虑兼容旧会话，就让 Hyprland session 管理由标准机制接管。

同时吸收这些 Hyprland 规则：

```conf
windowrule = match:fullscreen 1, idle_inhibit fullscreen

windowrule {
  name = steam-game-rule
  match:class = ^steam_app_\d+$
  border_size = 0
  content = game
  fullscreen = on
  workspace = 9 silent
  rounding = off
  float = off
  tile = off
}
```

本地还应删除废弃项：

```conf
gestures {
  workspace_swipe = off
}
```

上游已经移除它。本地保留只会增加升级噪音。

### 2.3 DMS/Quickshell/Matugen：可以作为新桌面 shell 方向

如果不考虑向后兼容，DMS/Quickshell 就不只是“长期可选项”，而是值得开一个明确迁移阶段：

- DMS 替代 Mako 通知中心、OSD、夜间模式、截图入口。
- Quickshell 作为统一 bar/control center。
- Matugen 从壁纸/主题生成 Hyprland、Rofi、Foot、Tmux 色彩。

但建议仍分两步：

1. 先把 Axiom 切到现有 Hyprland，确认 NVIDIA/Wayland 基础稳定。
2. 再用一个单独 PR 把 Mako/Waybar/自研 OSD 替换成 DMS/Quickshell/Matugen。

不是为了兼容旧系统，而是为了降低问题定位复杂度。

### 2.4 Steam/游戏：直接升级为主力游戏栈

上游 `modules/desktop/apps/steam.nix` 新增：

```nix
programs.steam.gamescopeSession.enable = true;
environment.systemPackages = [ pkgs.umu-launcher ];
```

本地已有：

- Steam
- Gamescope 基础 enable
- Gamemode
- Mangohud
- NTFS Steam library `compatdata` 修复

建议直接改成：

```nix
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  gamescopeSession.enable = true;
};

programs.gamemode.enable = true;
environment.systemPackages = [ pkgs.umu-launcher pkgs.mangohud ];
```

Axiom 是 9950X + RTX 5090，不应只做到“Steam 能打开”，而要把 Proton/Gamescope/Gamemode/Umu/Mangohud 做成默认主线。

### 2.5 Workstation sysctl：直接吸收

上游 workstation profile 增加：

```nix
boot.kernel.sysctl = {
  "kernel.sched_cfs_bandwidth_slice_us" = 3000;
  "net.ipv4.tcp_fin_timeout" = 5;
  "kernel.split_lock_mitigate" = 0;
  "vm.max_map_count" = 2147483642;
  "fs.inotify.max_user_watches" = 524288;
};
```

本地只有 `fs.inotify.max_user_watches`。

建议直接吸收其余项。它们不是向后兼容问题，而是 Axiom 这种主力桌面/游戏/开发工作站应该有的默认参数。

### 2.6 PDF/Office/Lutris/Flatpak：直接补齐

上游新增模块：

```nix
desktop.media.pdf.enable = true;
desktop.apps.libreoffice.enable = true;
desktop.apps.lutris.enable = true;
services.flatpak.enable = true;
```

建议本地直接加模块并在 Axiom 启用：

- PDF：`ghostscript`、`poppler-utils`、`wkhtmltopdf`、`pdfgrep`、`img2pdf`、`ocrmypdf`
- Office：`libreoffice`、aspell dictionaries
- Game launchers：`lutris`
- Escape hatch：Flatpak + Flathub

这是 Windows 替代体验的底线，不应再当作“以后需要再装”。

### 2.7 Chrome 模块要重写

本地 `modules/desktop/browsers/chome.nix` 目前只是：

```nix
user.packages = [ google-chrome ];
```

如果 Axiom 要作为主力机，Chrome 必须是一等公民：

- Wayland/Ozone flags
- GPU rasterization / Vulkan / VAAPI flags
- DRM/Widevine 验收
- WebRTC/portal/screen sharing 验收
- Fcitx5/Rime 输入验收

建议不要兼容旧 Chrome 模块，直接重写成 `chrome.nix`，并修掉文件名 `chome.nix` 这个 typo。

### 2.8 XDG SSH wrapper 修复

上游 `xdg.nix` 尊重显式参数：

- `ssh -F custom_config` 不应被 wrapper 覆盖。
- `scp -F custom_config` 不应被 wrapper 覆盖。
- `ssh-copy-id -i custom_key` 不应被 wrapper 覆盖。

本地可以直接吸收这个行为，不需要保留旧 wrapper 的强制注入方式。

### 2.9 `hey sync --host`

上游给 `hey sync` 加了：

```janet
host [--host name]
```

本地 `sync` 已经有 Darwin/NixOS 分流。建议直接合并 `--host`，并让所有 rebuild 都支持显式 host：

```sh
hey sync --host axiom build
hey sync --host axiom switch
hey sync --host charlie switch
```

这是多主机 dotfiles 的基础能力。

---

## 3. 应该删除或重写的东西

如果不考虑向后兼容，下面这些不建议再维护：

1. **bspwm / sxhkd / X11 theme 分支**  
   Axiom 直接 Wayland-only。旧 X11 配置只会拖慢桌面收敛。

2. **Dunst 与 Mako 双通知路线**  
   Wayland-only 后保留 Mako，或迁移到 DMS。不要两套并存。

3. **swayidle / hypridle 双实现长期并存**  
   本地现在偏向 swayidle，因为 hypridle/hyprlock 有历史 bug。可以短期保留 swayidle，但不要再抽象成双实现兼容层。

4. **旧 Spotify/ncmpcpp/MPD 方向**  
   上游已经转 Feishin。若 C1 没有强 MPD 需求，本地可以直接删除 ncmpcpp 配置，音乐栈改成 GUI-first + beets 管理。

5. **旧 theme/polybar/Xresources 资产**  
   Wayland-only 后只保留 GTK/Qt/cursor/Rofi/Foot/Hyprland/Waybar 或 DMS 主题链路。

6. **服务器服务模块对 Axiom 的默认影响**  
   Axiom 不应背着 Gitea/Discourse/Jellyfin/Prometheus 等通用服务模块复杂度。服务器模块可以迁移到 server-only 子树，桌面主机不导入。

---

## 4. Axiom 当前状态判断

`hosts/axiom/default.nix` 当前优势：

- 硬件定位明确：Ryzen 9950X + RTX 5090。
- 已启用 `cpu/amd`、`gpu/nvidia`、`audio`、`audio/realtime`、`ssd`、`bluetooth`、`wifi`。
- 已启用 Steam。
- 已启用 Chrome + Librewolf。
- 已启用 fcitx5-rime。
- Dev 环境完整：Node/Deno/Rust/Python/Java。
- 有 Docker、SSH、Calibre。
- NTFS 支持已开。

主要短板：

1. **还在启用 `bspwm`。** 这和主力 Wayland/NVIDIA 桌面路线冲突。
2. **没有 monitor 声明。** RTX 5090 主力机大概率有高刷/多屏，必须 declarative。
3. **Chrome 模块太弱。** 主力机 Chrome 不能只是安装包。
4. **Steam 游戏栈还没完整。** 缺 `gamescopeSession`、`umu-launcher`、game workspace rules。
5. **Office/PDF/Flatpak/Lutris 缺基础模块。** 这会让“替代 Windows”体验断档。
6. **workstation profile 少性能 sysctl。** 上游新增项应直接吸收。
7. **网络栈有潜在冲突。** workstation 默认 systemd-networkd，Axiom hardware 又开 NetworkManager，需要选择一个，不要双栈。

---

## 5. 推荐实施路线

### Phase 1：硬切 Axiom 到 Wayland 主线

目标：删除桌面兼容包袱，先让 Axiom 进入唯一主路径。

建议改动：

```nix
desktop = {
  hyprland = {
    enable = true;
    monitors = [
      # TODO: 实机填 output/mode/position/scale/primary
    ];
  };
  apps = {
    rofi.enable = true;
    thunar.enable = true;
    steam.enable = true;
    libreoffice.enable = true;
    lutris.enable = true;
  };
  browsers = {
    default = "chrome";
    librewolf.enable = true;
    chrome.enable = true;
  };
  term = {
    default = "foot";
    foot.enable = true;
  };
  media = {
    pdf.enable = true;
    video.enable = true;
    graphics.enable = true;
  };
};
services.flatpak.enable = true;
```

同时删除 Axiom 的 `bspwm.enable = true`。

### Phase 2：模块级吸收上游低风险收益

目标：把上游好改动直接落地。

- `steam.nix` 加 `gamescopeSession.enable` 和 `umu-launcher`。
- `workstation.nix` 加上游 sysctl。
- `xdg.nix` 合并 SSH wrapper 参数保护。
- `sync.janet` 合并 `--host`。
- 新增 `media/pdf.nix`、`apps/libreoffice.nix`、`apps/lutris.nix`、`services/flatpak.nix`。
- `hyprland.conf` 删除废弃 gestures，补 fullscreen idle inhibit 和 game rules。

### Phase 3：删除旧桌面代码

目标：降低长期维护成本。

- 删除 `modules/desktop/bspwm.nix`。
- 删除 `config/bspwm/**`。
- 删除 `config/sxhkd/**`。
- 删除 `modules/themes/autumnal/bspwm.nix`。
- 删除 `modules/services/dunst.nix`。
- 删除 X11-only theme/config 分支。
- 删除未再使用的 Polybar/Xresources 资产。

### Phase 4：重写桌面 shell

目标：选择 Mako/Waybar 自研链路，或者全面迁移 DMS/Quickshell。

建议路线：

- 如果要快：保留本地 Waybar/Mako/Rofi/OSD，先 polish。
- 如果要收敛到上游：引入 `dms-shell + quickshell + matugen`，并删除 Mako/Waybar/自研 OSD。

不建议长期“两套都留”。

---

## 6. Axiom 验收清单

### 桌面/显示

- [ ] Hyprland 是唯一启用桌面。
- [ ] 没有 bspwm/sxhkd/X11 theme 依赖。
- [ ] 主屏/副屏位置正确。
- [ ] 高刷新率生效。
- [ ] XWayland 应用默认落在主屏。
- [ ] 全屏视频/游戏不会触发 idle lock。
- [ ] 锁屏/DPMS/待机唤醒可靠。

### NVIDIA/图形

- [ ] `nvidia-smi` 正常。
- [ ] CUDA toolkit 可用。
- [ ] Vulkan 基本测试通过。
- [ ] VAAPI/硬解在 Librewolf/Chrome/mpv 中可验证。
- [ ] Wayland 下无光标/闪烁/黑屏问题。
- [ ] suspend/resume 后显示、音频、网络正常。

### 浏览器/输入法

- [ ] Chrome 是 Wayland native。
- [ ] Chrome GPU 加速启用。
- [ ] DRM 视频可播放。
- [ ] Google Meet/Zoom/Discord 屏幕共享正常。
- [ ] Fcitx5/Rime 在 Chrome/Librewolf/Electron/终端可用。

### 游戏

- [ ] Steam 正常启动。
- [ ] Proton 游戏可运行。
- [ ] `gamescopeSession` 可用。
- [ ] `gamemoderun` 可用。
- [ ] `umu-launcher` 可启动非 Steam exe。
- [ ] `mangohud` 可用。
- [ ] Steam 游戏窗口进入 workspace 9。

### 日常桌面

- [ ] LibreOffice 可打开 docx/xlsx/pptx。
- [ ] PDF grep/OCR/img2pdf 可用。
- [ ] Thunar 可打开目录、挂载盘、生成缩略图。
- [ ] Flatpak/Flathub 可作为兜底。
- [ ] Lutris 可安装/启动测试 launcher。
- [ ] Wi-Fi/蓝牙/音频/电源菜单有 GUI 或 launcher 入口。

### 工具链

- [ ] `hey sync --host axiom build` 可用。
- [ ] `ssh -F custom_config host` 不被 wrapper 破坏。
- [ ] `ssh-copy-id -i custom_key host` 不被 wrapper 破坏。
- [ ] workstation sysctl 生效。

---

## 7. 具体落地建议列表

按优先级排序：

1. **Axiom 直接切 Hyprland，删除 `bspwm.enable = true`。** 这是最大收益点。
2. **给 Axiom 写 monitor 配置。** 没有 monitor 声明，高刷/多屏体验无法稳定。
3. **Steam 模块加 `gamescopeSession` 和 `umu-launcher`。** 游戏主力机必备。
4. **workstation profile 加上游 sysctl。** 低风险、高收益。
5. **新增并启用 PDF/LibreOffice/Lutris/Flatpak。** 补齐 Windows 替代基础体验。
6. **重写 Chrome 模块。** 文件名从 `chome.nix` 改为 `chrome.nix`，并加入 Wayland/GPU flags。
7. **Hyprland config 删除废弃项，补 fullscreen idle inhibit 和 Steam game rules。** 减少升级噪音，提高游戏体验。
8. **合并 `hey sync --host`。** 多机管理基础能力。
9. **修 XDG SSH wrapper。** 降低工具链踩坑概率。
10. **删除 X11/bspwm/sxhkd/Dunst/Polybar 旧链路。** 不再为旧桌面支付维护成本。
11. **再决定 DMS/Quickshell/Matugen 是否接管桌面 shell。** 要么完整迁移，要么不引入，不要半套。

---

## 8. 推荐最终形态

我建议 Axiom 的最终定位是：

> **C1 的高性能 Wayland 主力工作站：NixOS + Hyprland-only + RTX 5090 + Chrome/Librewolf + Steam/Proton/Gamescope/Umu + PDF/Office/Flatpak 兜底 + 完整中文输入 + 明确 NVIDIA/桌面验收。**

技术路线：

- 桌面：Hyprland-only
- 会话：UWSM + greetd
- 状态栏/控制中心：短期 Waybar/Mako/Rofi，长期 DMS/Quickshell 二选一
- 浏览器：Chrome 主力 + Librewolf 隐私备用
- 游戏：Steam + Proton + Gamescope + Gamemode + Mangohud + Umu
- 媒体：mpv + ffmpeg-full + OBS 后续专项验证
- 日常：Thunar + LibreOffice + PDF tools + Flatpak
- 输入法：fcitx5-rime
- 主题：Wayland-only 主题链路，删除 X11/Polybar/Xresources 残留

一句话：**不要再把 Axiom 做成兼容旧 dotfiles 的机器；直接把它做成新的主力 Wayland 工作站基线。**
