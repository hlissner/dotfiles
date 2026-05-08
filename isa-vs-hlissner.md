# isabelroses/dotfiles vs hlissner/dotfiles 优缺点对比

> 对比对象：<https://github.com/isabelroses/dotfiles> 与 <https://github.com/hlissner/dotfiles>  
> 范围：只比较两个上游 dotfiles 的设计取向、桌面体验、Nix 架构、维护成本与可借鉴价值。  
> 排除项：不考虑本机配置、不讨论 Axiom、不做本地迁移建议。

## 0. 结论先行

两者都是成熟的 NixOS/Hyprland dotfiles，但目标气质不同：

| 维度 | isabelroses/dotfiles | hlissner/dotfiles |
|---|---|---|
| 核心气质 | 桌面产品化、体验完整、视觉统一 | 系统工程化、强收敛、低层工具扎实 |
| 最强项 | Hyprland + Quickshell + Chromium/Discord/OBS + Catppuccin 桌面闭环 | NixOS module hygiene + XDG discipline + Hyprland-only 收敛 + 游戏/工作站调优 |
| 桌面体验 | 更接近“现代个人电脑产品” | 更接近“高级用户自维护工作站” |
| 架构风格 | 自成体系的 `garden` 抽象，用户级 GUI 配置很丰富 | `hey`/模块体系，直接、脚本化、偏工程师工具箱 |
| 维护成本 | UI/QML/主题/客户端配置多，维护面广 | 删除旧模块后更轻，但依赖个人脚本和强约束习惯 |
| 可复制性 | 概念可复制，整套搬运成本高 | 单个模块/脚本更容易抽取，整仓有个人历史包袱 |
| 风险 | Quickshell/QML 与客户端 patch 复杂度 | aggressive cleanup、unstable/DMS/Matugen 路线漂移 |

一句话：**Isabel 更像“桌面体验蓝图”，hlissner 更像“系统收敛与维护纪律蓝图”。**

---

## 1. 总体定位

### 1.1 Isabel

Isabel 的仓库重点是把 NixOS 桌面做成完整日用电脑：

- Hyprland 是桌面核心。
- Quickshell 提供 bar、quick settings、蓝牙、音频、网络、媒体、通知、OSD、systray。
- Chromium、Discord、OBS、Ghostty、mpv 等 GUI 应用被当作一等公民配置。
- Catppuccin、字体、GTK/Qt、MIME defaults 等视觉链路覆盖广。
- Secure Boot、dual boot Windows、TPM、YubiKey 等主力机可靠性因素进入模型。

她的 dotfiles 不是只装软件，而是在塑造一台“真的每天用”的桌面电脑。

### 1.2 hlissner

hlissner 的仓库重点是把长期积累的 NixOS 配置做收敛：

- 最新上游主动删除 X11/bspwm/sxhkd/ncmpcpp/Waybar/Dunst/旧服务模块。
- Hyprland 路线转向 UWSM、greetd、DMS、Quickshell、Matugen。
- Steam、Gamescope、Gamemode、Umu、Mangohud 等游戏路径更明确。
- XDG hygiene、SSH wrapper、fake HOME、Steam HOME jail 等低层细节做得深。
- workstation sysctl、kernel、NVIDIA、audio realtime 等系统参数有强工程师取向。

他的 dotfiles 更像一个高级用户多年维护后形成的“系统工程工具箱”。

---

## 2. Isabel 的优点

### 2.1 桌面产品感强

Isabel 的最大优势是完整桌面体验。Hyprland 不只是窗口管理器，而是被接进了控制中心、通知、蓝牙、音频、网络、媒体、截图、录屏、锁屏、屏幕共享等链路。

这让她的配置更适合作为“Linux 桌面如何接近 Windows/macOS 完整度”的参考。

### 2.2 Quickshell 使用深入

她的 Quickshell 不是简单 bar，而是包含：

- quick settings popup
- Bluetooth panel
- PipeWire volume control
- network status
- battery / UPower
- media players
- notifications
- OSD
- systray

这部分价值很高，因为许多 tiling WM 配置最大短板就是缺少统一控制中心。

### 2.3 GUI 应用配置更贴近日常用户

Isabel 对 Chromium、Discord、OBS、mpv、Spotify、文件管理器、MIME defaults 等 GUI 细节关注更多。

尤其 Chromium 配置有：

- Widevine/DRM
- Wayland/Ozone flags
- GPU rasterization / zero-copy
- runtime cache
- native messaging
- 常用扩展

这说明她更重视浏览器、会议、媒体、通讯这些实际桌面成败点。

### 2.4 多媒体与创作链路完整

她的 mpv/OBS/media 配置更成熟：

- mpv `gpu-next`、Vulkan、hwdec、modern UI、SponsorBlock、thumbfast
- OBS CUDA/wlrobs/多推流/转场插件
- creation/streaming profile
- Gimp/Inkscape/Chatterino 等创作或直播工具

对“主力桌面”而言，这比只装播放器更有参考价值。

### 2.5 可靠性与安全意识更偏普通主力机

Isabel 的配置明确考虑：

- Secure Boot
- dual boot Windows
- TPM
- YubiKey
- 蓝牙多 profile
- NetworkManager/iwd/resolved
- GUI 网络与蓝牙入口

这类因素不是炫技，但决定一台 Linux 桌面能不能长期替代常规个人电脑。

---

## 3. Isabel 的缺点

### 3.1 `garden` 抽象迁移成本高

她的模块体系与 `garden` 语义绑定很深。直接搬配置时，很多设计不是单个 Nix 文件能复用，而要理解整套 device/profile/program 模型。

这会降低外部用户的“局部摘取”效率。

### 3.2 Quickshell/QML 维护成本高

Quickshell 带来的桌面产品感很强，但代价是：

- QML 自定义代码多。
- UI 状态、系统服务、DBus、PipeWire、Bluetooth、Network 等集成复杂。
- 上游 API 或 shell 行为变化时维护成本高。

它适合长期经营，不适合轻量复制。

### 3.3 客户端 patch 有风险

Discord/Moonlight/OpenAsar 一类 patch 能提升体验，但也带来：

- 兼容风险
- 客户端更新风险
- 账号或 ToS 风险
- debug 难度

这种配置体现个人偏好，不一定适合作为通用基线。

### 3.4 架构精致但重

Isabel 的仓库更像一个完整 ecosystem。优点是统一，缺点是进入成本高。

如果只想借鉴某个点，比如 browser flags 或 mpv 配置，可能需要剥离很多上下文。

---

## 4. hlissner 的优点

### 4.1 收敛能力强

hlissner 最新上游最明显的优点是敢删：

- 删除 X11/bspwm/sxhkd
- 删除 ncmpcpp/旧音乐配置
- 删除 Waybar/Dunst/多种旧服务模块
- 删除旧主题资产

这体现一种重要维护纪律：不长期保留不再服务主线的兼容层。

### 4.2 NixOS 模块边界清晰

他的模块粒度相对直接：

- `modules/desktop/apps/steam.nix`
- `modules/desktop/media/pdf.nix`
- `modules/profiles/hardware/audio.nix`
- `modules/profiles/role/workstation.nix`
- `modules/xdg.nix`

比起大型自定义生态，这种模块更容易单独阅读和抽取。

### 4.3 XDG hygiene 很强

hlissner 对 `$HOME` 污染、XDG 目录、fake HOME、Steam/Firefox/SSH 等行为非常敏感。

典型例子：

- `XDG_FAKE_HOME`
- Firefox/LibreWolf wrapper
- Steam HOME jail
- SSH wrapper
- sqlite/wget/readline/less/mysql/psql 等历史文件位置

这类细节不显眼，但长期维护 dotfiles 时非常有价值。

### 4.4 游戏与 workstation 参数务实

上游最新 Steam/workstation 变化很实用：

- `gamescopeSession.enable`
- `umu-launcher`
- `gamemode`
- `mangohud`
- `vm.max_map_count`
- `split_lock_mitigate`
- `tcp_fin_timeout`
- `sched_cfs_bandwidth_slice_us`

这不是“漂亮配置”，而是面向真实桌面/游戏负载的工程修补。

### 4.5 个人脚本生态成熟

`hey` 体系、hook、sync、gc、rofi menu、Hyprland helper scripts 等组成了一套高效个人运维工具。

它的优点是日常操作路径短，很多重复工作被脚本化。

---

## 5. hlissner 的缺点

### 5.1 桌面产品感不如 Isabel 完整

hlissner 新路线有 DMS/Quickshell/Matugen，但从配置呈现看，它更像工程师自用桌面，而不是完整“用户产品”。

相比 Isabel，它对 Chromium、Discord、OBS、控制中心、GUI 通讯、会议等普通桌面体验的显式覆盖较弱。

### 5.2 个人历史包袱重

虽然上游在删除旧模块，但 `hey`、fake HOME、wrapper、hooks、个人脚本仍然很个人化。

这些脚本对作者很高效，但外部复用者需要理解他的命令习惯和目录语义。

### 5.3 aggressive cleanup 可能牺牲通用性

删除 X11、旧服务、旧桌面组件能降低维护成本，但也让仓库变得更单一路线。

这对作者是优点，对想借鉴多场景模块的人可能是缺点。

### 5.4 追 unstable / xanmod / DMS 路线有漂移风险

上游使用 `nixos-unstable`、`linux_xanmod_latest`、DMS/Matugen/Quickshell-git 等组件，更新收益大，但也更容易被上游 API 或包状态影响。

这种路线适合愿意频繁维护的人，不适合低维护成本用户。

### 5.5 GUI 应用细节不如 Isabel 强

hlissner 对系统层和脚本层很强，但在现代桌面的关键 GUI 细节上，Isabel 更突出：

- Chromium flags / Widevine / extensions
- Discord patch / screen sharing
- OBS CUDA/wlrobs streaming profile
- Quickshell 控制中心功能广度
- 统一主题/MIME/文件管理器

---

## 6. 分项对比

### 6.1 Nix 架构

| 项目 | Isabel | hlissner |
|---|---|---|
| 抽象方式 | `garden` profile/device/program 模型 | `hey` + NixOS modules + scripts |
| 可读性 | 高层语义清晰，但需理解 garden | 文件直观，但需理解 hey 习惯 |
| 可摘取性 | 单点摘取较难 | 单模块摘取较容易 |
| 长期维护 | 统一但重 | 直接但个人化 |

结论：**Isabel 更像 framework，hlissner 更像 toolkit。**

### 6.2 桌面 shell

| 项目 | Isabel | hlissner |
|---|---|---|
| 主线 | Hyprland + Quickshell | Hyprland + DMS/Quickshell/Matugen |
| 控制中心 | 功能非常完整 | 新路线正在收敛，偏工具化 |
| 通知/OSD | Quickshell 深度整合 | DMS IPC / scripts |
| 维护成本 | QML 复杂 | DMS/Matugen 依赖新，但配置更少 |

结论：**Isabel 更成熟，hlissner 更激进。**

### 6.3 浏览器与通讯

| 项目 | Isabel | hlissner |
|---|---|---|
| Chromium | 配置细，含 Wayland/GPU/Widevine/extensions | 不突出 |
| Firefox/LibreWolf | 不是最核心亮点 | XDG/隐私/配置很细 |
| Discord | 深度配置甚至 patch | 不突出 |
| 会议/屏幕共享 | 显式作为桌面体验考虑 | 更偏底层 portal/Wayland 基础 |

结论：**现代 GUI 日用体验 Isabel 明显更强。**

### 6.4 多媒体与创作

| 项目 | Isabel | hlissner |
|---|---|---|
| mpv | GPU/Vulkan/UI/SponsorBlock/thumbfast 细节多 | 基础 mpv/hwdec |
| OBS | CUDA/wlrobs/streaming plugins | 有 capture 模块但不深 |
| 音乐 | Spotify/媒体控制/桌面集成 | Feishin/beets/picard/flac workflow |
| 创作 | Gimp/Inkscape/streaming profile | Reaper/graphics/PDF 工具更工程化 |

结论：**Isabel 偏消费/直播/媒体体验，hlissner 偏个人媒体库和工具处理。**

### 6.5 系统工程与维护

| 项目 | Isabel | hlissner |
|---|---|---|
| XDG discipline | 有，但不是主要卖点 | 非常强 |
| Workstation tuning | 有主力机意识 | sysctl/kernel/audio/NVIDIA 更直接 |
| 删除旧代码 | 不突出 | 非常突出 |
| 脚本自动化 | 有，但不是核心 | `hey` 体系是核心 |

结论：**系统工程和长期维护纪律 hlissner 更强。**

### 6.6 安全与可靠性

| 项目 | Isabel | hlissner |
|---|---|---|
| Secure Boot | 显式配置 | 不突出 |
| YubiKey/TPM | 显式能力建模 | 不突出 |
| SSH/XDG | 有基础 | wrapper 细节强 |
| Dual boot | 显式考虑 | 更偏 NTFS/Steam library 实用修补 |

结论：**Isabel 更像普通主力机安全模型，hlissner 更像工程师运维安全习惯。**

---

## 7. 谁更适合参考什么

### 7.1 参考 Isabel 的场景

适合从 Isabel 学：

- 如何把 Hyprland 做成完整桌面产品。
- 如何设计 Quickshell 控制中心。
- 如何把 Chromium/Discord/OBS/mpv 作为一等桌面应用配置。
- 如何做统一主题、字体、MIME、文件管理器、GUI 入口。
- 如何考虑 Secure Boot、dual boot、TPM、YubiKey 这类主力机因素。

不适合从 Isabel 学：

- 快速、低成本的模块摘取。
- 极简维护模型。
- 大量 QML/UI 代码以外的轻量桌面路线。

### 7.2 参考 hlissner 的场景

适合从 hlissner 学：

- 如何删掉旧路线并收敛维护面。
- 如何设计可组合的 NixOS module。
- 如何做 XDG hygiene 和 `$HOME` 污染隔离。
- 如何用个人脚本缩短日常运维路径。
- 如何给 workstation/Steam/NVIDIA/audio 做务实系统调优。

不适合从 hlissner 学：

- 面向普通用户的完整 GUI 桌面体验。
- Chromium/Discord/OBS 等现代应用的精细配置。
- 稳定保守、低更新频率的发行路线。

---

## 8. 最终评价

Isabel 的优点是：**完整、现代、像产品、重视 GUI 日用体验。**

Isabel 的缺点是：**抽象重、QML/Quickshell 维护成本高、客户端 patch 风险更大、局部复用成本高。**

hlissner 的优点是：**直接、务实、系统细节强、维护纪律强、局部模块更容易摘取。**

hlissner 的缺点是：**个人脚本语义重、桌面产品感较弱、GUI 应用体验覆盖不如 Isabel、unstable/DMS/Matugen 路线更激进。**

一句话总结：

**如果目标是“Linux 桌面像现代个人电脑一样完整”，Isabel 更值得看；如果目标是“长期维护一套收敛、干净、强工程纪律的 NixOS dotfiles”，hlissner 更值得看。**
