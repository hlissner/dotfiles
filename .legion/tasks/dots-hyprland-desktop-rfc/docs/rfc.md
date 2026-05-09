# RFC：Axiom 向 end4 `ii` 桌面推进的 Phase 4 实现

> 状态：已评审，PASS；Phase 4 substrate 已实现
> 类型：RFC Standard，implementation-bound
> 日期：2026-05-09
> 任务：`.legion/tasks/dots-hyprland-desktop-rfc/`

## 执行摘要

本任务从历史 design-only RFC 续跑为实现任务。新的方向以 `end4.md` 为准：Axiom 不再把旧 Axiom dock、guide、按钮或 `autumnal` 桌面视觉作为兼容目标，而是把 end4 的 `ii` / `IllogicalImpulseFamily` 桌面体验作为目标形态，同时继续由 NixOS 声明系统集成、host facts、权限、服务和依赖。

Phase 4 的实现重点不是再设计一个 Axiom-native shell，而是补齐 end4 核心 shell surfaces 所需的声明式服务能力：launcher、overview、左右侧栏、控制中心、通知中心、OSD、wallpaper selector、session/lock、polkit-facing UX，以及 network、Bluetooth、audio、brightness、MPRIS、resource usage、tray、notifications 和 clipboard 等后端能力。

本 PR 的边界是声明式服务/依赖/权限层。若当前 base 仍未完整落地 Phase 1-3 的 end4 `ii` shell tree、Hyprland 分层和 matugen pipeline，本 PR 不用旧 Axiom 体验补回目标缺口；它应记录缺口，并确保 Phase 4 依赖和 NixOS service ownership 对后续 `ii/shell.qml` runtime 可追溯。

## 目标

- 让 Axiom Phase 4 的服务依赖、user services、permissions 和 host capabilities 由 Nix 声明。
- 使 end4 launcher、overview、左右侧栏、控制中心、通知中心和 OSD 所需的系统工具可从 Nix 配置追溯。
- 将 RFC 的阶段模型改成 `end4.md` 的阶段模型，而不是历史的 Axiom-native incremental shell model。
- 将主题决策改成 end4 Material/Matugen 方向：`IllogicalImpulseFamily` 是默认 panel family，Material Symbols / Google Sans-style fonts 与 Qt/Kirigami 依赖要被承认，mutable generated colors 不进入 Nix store。
- 保持 Axiom 强项：NixOS host facts、UWSM/greetd/portal ownership、declarative monitor/workspace/default-app configuration、Darwin isolation。

## 非目标

- 不运行 end4 `setup`，不把 unmanaged live `~/.config` 变成真源。
- 不维护 `axiom-shell` 与 end4 `ii` 两套主 shell；旧 Axiom shell 只能作为过渡缺口，不是设计目标。
- 不维护 `autumnal` 与 matugen 两套桌面主题真源；`autumnal` 仅可作为非桌面 fallback 或后续删除对象。
- 不在 Phase 4 实现截图、录屏、OCR、翻译、视觉搜索或 AI policy；这些分别属于 Phase 5/6。
- 不把 cloud/API key、generated color outputs、clipboard secrets 或 shell runtime state 写入仓库或 Nix store。

## 当前基线

- Axiom 已有 NixOS、Hyprland、UWSM、greetd、portals、`hyprland-session.target` 和 `quickshell.service` ownership。
- 当前 base 仍包含 Axiom-native Quickshell sources such as `config/quickshell/axiom-shell/*`；它们不能再作为目标体验真源。
- `modules/desktop/quickshell.nix` 已声明 Quickshell service、search/control helper、部分 runtime packages 和 clipboard watcher，但还不完整覆盖 end4 Phase 4 service surface。
- `modules/desktop/hyprland.nix` 仍生成 `hyprland.pre.conf` 并包含 old guide launcher/window rules；这与 `end4.md` 的 Phase 2/4 目标有冲突，后续应迁移到 end4 source/layering model。
- Axiom host 已启用 `wifi`、`bluetooth`、`audio`、`audio/realtime`，并有 NetworkManager、BlueZ、PipeWire/WirePlumber 基础，但缺少 Phase 4 明确需要的 group、i2c、power-profile、keyring/polkit 和 full UI dependency closure。

## 设计原则

- end4 `ii` 是产品目标，Nix 是部署和系统集成真源。
- 功能采用以 `end4.md` 阶段为准，而不是以历史 RFC 的 Axiom shell 兼容性为准。
- Declarative ownership beats runtime scripts：packages、groups、kernel modules、services、user services 和 generated-state directories 都应能在 Nix 或任务文档中定位。
- Fallback tools 可以存在，但只能作为 UI 未在线或 inline control 不完整时的救援入口。
- Generated theme state 是 runtime mutable state；Nix 只管模板、脚本、依赖和初始约定。

## 备选方案

### 方案 A：立即整体导入 end4 `ii` 和所有 upstream dependencies

- 优点：最接近 `end4.md` 的目标表面。
- 缺点：大规模代码导入，review 面巨大；upstream installer/mutable assumptions 与 Nix/UWSM 冲突；会把 Phase 1-3 和 Phase 4 混成不可回滚大改。
- 决策：拒绝本轮作为实现方式。可以作为单独 Phase 1/2 补齐任务，但必须保持 Nix ownership。

### 方案 B：继续扩展 `axiom-shell` 的本地能力

- 优点：当前代码可构建，改动小。
- 缺点：违背当前用户要求和 `end4.md`，会继续维护旧 Axiom dock/guide/button 目标，并让 theme 方向保留在 `autumnal`。
- 决策：拒绝作为目标；只允许把现存代码视作过渡基线。

### 方案 C：先声明 Phase 4 service substrate，明确旧 shell 缺口

- 优点：本轮可在可评审范围内补齐 end4 Phase 4 所需 NixOS capabilities；不会把 unmanaged upstream installer 引入仓库；后续 `ii/shell.qml` 可以直接依赖这些服务和工具。
- 缺点：若 Phase 1-3 未完成，单靠本 PR 不能让所有 end4 QML surface 在 live session 中完整可用。
- 决策：选择。它是当前 Phase 4 最小正确切片。

## end4.md 对齐阶段模型

### Phase 1：Quickshell `ii` shell family

目标：默认 panel family 是 end4 `IllogicalImpulseFamily`，`systemctl --user restart quickshell.service` 能加载 `ii/shell.qml`，旧 Axiom dock/guide/button 不再作为成功条件。

Nix 必须承认的基础依赖包括 `quickshell`、Qt6/Kirigami/QML multimedia/positioning/sensors/svg/wayland/qt5compat、`kdialog`、`syntax-highlighting`、`adwaita-icon-theme`、Material Symbols 和 Google Sans-style fonts。

### Phase 2：NixOS-native Hyprland 分层

目标：采用 end4 `hyprland.conf` source 汇总风格和 shell IPC model，同时保留 monitor/workspace/default apps 由 Nix/host 声明。`hyprland.pre.conf` 不再是长期主干。

### Phase 3：Nix 管理 end4 theme/wallpaper chain

目标：matugen 和 wallpaper chain 由 Nix 声明依赖、模板和初始目录；mutable generated colors 只写 runtime state/config/cache targets。`autumnal` 不再是桌面视觉真源。

### Phase 4：声明式补齐 end4 核心服务能力

目标：launcher、overview、左右侧栏、控制中心、通知中心、OSD、wallpaper selector、session/lock 和 polkit-facing UX 有完整依赖、服务、权限和 fallback tools。

本轮实现范围：补齐 NixOS/user service substrate，包括 NetworkManager、Bluetooth、PipeWire/WirePlumber、power-profiles-daemon、keyring/polkit、cliphist watcher、i2c/DDC brightness support、tray/notifications/media/resource tooling、fallback control apps。

### Phase 5：截图、录屏、OCR、翻译、视觉搜索

保留 end4 UX 方向，但云视觉/API key 必须有 policy gate。当前不实现。

### Phase 6：end4 AI 与本机 policy

保留 AI UI/服务结构，但 API key 走 keyring，工具执行默认关闭并有可见 policy。当前不实现。

## Phase 4 设计

### Packages

`modules/desktop/quickshell.nix` 应成为 Phase 4 Quickshell runtime package owner。它应覆盖：

- shell/QML：Quickshell package、Qt/Kirigami/QML modules、icons、fonts；
- launcher/search：`fuzzel` fallback、`xdg-utils`、calculator/search helpers such as `libqalculate`/`qalc`；
- notifications/tray：`libnotify`、tray-compatible runtime assumptions；
- audio/media：`wireplumber` CLI/runtime availability, `pamixer` or equivalent, `pavucontrol` fallback, `playerctl`；
- brightness/display：`brightnessctl`、`ddcutil` and group/module prerequisites；
- network/Bluetooth：`networkmanager`/`nmcli`, `networkmanagerapplet` or KDE fallback, `bluez`, `blueman` or KDE BlueDevil fallback；
- resource/music/visual feedback：`cava`, `songrec`, lightweight process/resource tools where needed by shell surfaces；
- clipboard：`wl-clipboard`, `cliphist`；
- session/power: `wlogout`, `power-profiles-daemon` service/package path。

### Services And Permissions

Phase 4 must make system capabilities explicit:

- NetworkManager remains enabled by host/profile hardware declarations.
- Bluetooth remains enabled by the `bluetooth` hardware profile.
- PipeWire and WirePlumber remain enabled by `audio` / `audio/realtime` hardware profiles.
- `power-profiles-daemon` is enabled for Axiom's desktop session.
- `gnome-keyring` is enabled on Axiom so keyring-dependent shell and future AI/API-key storage have a service owner.
- Polkit is enabled and a graphical authentication agent/runtime is available for Quickshell/end4 polkit UX or fallback agents.
- User groups include `video`, `input`, and `i2c` for brightness/DDC/control surfaces.
- `i2c-dev` is loaded so DDC brightness controls can work with `ddcutil` on supported monitors.
- Clipboard history watcher uses the end4-compatible `wl-paste --watch cliphist store` pattern instead of a private Axiom-only helper when Phase 4 clipboard backend is enabled.

### Theme Ownership

Theme statements in code and docs should stop treating `autumnal` as desktop truth. Acceptable current behavior:

- Nix may still set an initial wallpaper path and install non-desktop fallback assets.
- Matugen templates/scripts and generated-state directories must be declared before runtime generation is relied on.
- Generated Quickshell/Hyprland/hyprlock/fuzzel/terminal colors are mutable runtime outputs, not committed Nix sources.
- The default target shell family is end4 `IllogicalImpulseFamily`; any old Axiom shell visuals are migration debt.

### Notification Ownership

Quickshell should own the end-user notification UX. The Nix layer must avoid silently starting conflicting notification daemons. If fallback tools are installed, they must not create a second notification server unless explicitly enabled.

## Implementation Plan

- Update `modules/desktop/quickshell.nix` to expand Phase 4 runtime dependencies and switch the clipboard watcher to `cliphist store`.
- Add options where needed so clipboard watcher and Phase 4 service extras can be disabled for rollback.
- Update desktop/NixOS modules or Axiom host config to enable keyring, polkit, power profiles, i2c, groups, and required fallback tools.
- Remove or stop installing old Axiom guide launcher/config where it conflicts with `end4.md` target UX.
- Leave actual Phase 5/6 surfaces out of scope and document missing runtime-only verification if graphical checks cannot run.

## Verification Strategy

- Run Nix formatting/static checks available in this repository.
- Evaluate or build Axiom toplevel when feasible: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Inspect evaluated/service configuration where full build is too expensive or blocked.
- Confirm no `autumnal` desktop-theme fallback language remains in RFC/walkthrough as target truth.
- Confirm no unmanaged end4 setup script, generated color output, API key, or live home-directory state is committed.
- Runtime follow-up on Axiom hardware: restart `quickshell.service`, verify `ii/shell.qml` once Phase 1 source exists, test launcher/overview/sidebars/control center/notification center, test audio/brightness/network/Bluetooth/power mode control, and ensure fallback apps launch.

## Rollback

- Merge-time rollback: revert this PR.
- Runtime rollback: disable Phase 4 service extras or clipboard watcher options, then switch/reboot to previous NixOS generation if needed.
- If Quickshell fails: stop `quickshell.service` and rely temporarily on Hyprland keybindings/fallback tools.
- If `cliphist` causes sensitive retention concerns: disable the watcher option and clear the user cliphist database.
- If brightness/DDC permissions cause issues: remove `i2c-dev`/`i2c` group from the host and keep `brightnessctl` only.

## Security And Privacy

- Clipboard history can expose secrets; retention and clear UX must be visible before broad enablement is considered final.
- Keyring enables safer secret storage but does not itself authorize AI/cloud/API features.
- Polkit agents must not bypass authentication; they only provide graphical prompts.
- Notification history can contain sensitive content; Quickshell ownership should include clear/dismiss controls.
- No API keys, generated color files, shell cache, or runtime notification/clipboard state belongs in Git.

## Open Questions

- Does the current implementation branch that imports `ii/shell.qml` exist outside `origin/master`, or should Phase 1 be redone in a follow-up PR?
- Which exact Qt font packages best map Material Symbols and Google Sans Flex in nixpkgs for the target channel?
- Should the `cliphist` watcher be enabled by default immediately, or default-on only for Axiom because this task is Axiom-specific?

## Decision

Proceed with方案 C：declare the end4 Phase 4 service substrate now, while treating incomplete `ii` source migration as explicit prior-phase debt rather than preserving old Axiom shell behavior. This matches the user's instruction to follow `end4.md` for theme direction and not preserve backward compatibility with the old Axiom desktop UX.

## References

- Task contract: `.legion/tasks/dots-hyprland-desktop-rfc/plan.md`
- Historical research: `.legion/tasks/dots-hyprland-desktop-rfc/docs/research.md`
- Historical llm-wiki: `.legion/tasks/dots-hyprland-desktop-rfc/docs/llm-wiki-dots-hyprland.md`
- Historical comparison: `.legion/tasks/dots-hyprland-desktop-rfc/docs/comparison.md`
- Current Quickshell module: `modules/desktop/quickshell.nix`
- Current Hyprland module: `modules/desktop/hyprland.nix`
- Current Axiom host: `hosts/axiom/default.nix`
