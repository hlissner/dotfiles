# Axiom Quickshell Quick Controls and OSD - 日志

## 2026-05-09

- 用户要求继续实现 Stage 3。
- 按 `legion-workflow` 恢复 `dots-hyprland-desktop-rfc` Stage 3：Quick Controls 与 OSD。
- 确认当前基线：Stage 1 notification center 和 Stage 2 search/actions 已合并；dock 仍保留 `WIFI`/`BT`/`VOL`/`PWR` external controls；media keys still call `hey .osd` / `playerctl`。
- 创建新的 implementation task `axiom-quickshell-quick-controls-osd`，范围为 quick controls + OSD only，不进入 Stage 4/5。
- 产出 task-local RFC：`docs/rfc.md`。关键决策是 Quickshell UI + small fixed-verb control helper + external fallbacks；Quickshell owns quick controls/OSD，Nix owns packages/helpers/services，Hyprland owns keybindings/wrapper routing only。
- 执行 RFC 评审：`docs/review-rfc.md`，结论 PASS，无阻塞问题。实现建议包括保持 DBus/control-center scope shallow、OSD wrappers 保留 fallback、media-key semantics 不回归、新 actions 固定 verb/static argv，并显式验证 Stage 1/2 regressions。
- 进入 `git-worktree-pr` envelope：base ref `origin/master` at `7519635feec70cf2570b2df2ec31b1a9206ee84d`，branch `legion/axiom-quickshell-quick-controls-osd-stage3`，worktree `.worktrees/axiom-quickshell-quick-controls-osd`。
- Engineer 阶段完成初版实现：新增 `QuickControlsPanel.qml`、`OsdOverlay.qml`、fixed-verb `axiom-control-helper.py`，rewire dock quick-control entries to shell panel, add OSD IPC method and route media keys through helper while preserving `hey .osd` volume/brightness fallback path。
- Verify 阶段完成：`docs/test-report.md` 记录 PASS with runtime gaps。通过 helper syntax/status/media smoke、OSD zsh syntax、Nix parse/eval/build、Hyprland config verification、`qmllint`、scope/fallback/Variants greps。Live Quickshell/layer-shell behavior 和 disruptive toggles 未在 headless 环境执行。
- Review Change 阶段完成：`docs/review-change.md` 结论 PASS，无阻塞问题。残余风险是 live Quickshell layer-shell/focus/multi-screen/OSD timing 未验证，以及硬件服务可用性差异。
- Walkthrough 阶段完成：`docs/report-walkthrough.md` 和 `docs/pr-body.md` 已生成。
- Legion wiki 写回完成：新增 `.legion/wiki/tasks/axiom-quickshell-quick-controls-osd.md`，更新 `index.md`、`decisions.md`、`patterns.md` 和 `log.md`。

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|---|---|---|---|
| Stage 3 使用新任务 `axiom-quickshell-quick-controls-osd` | 父任务是 design-only；Stage 1/2 均已用独立 implementation task 交付 | 改写父 RFC 任务，已拒绝 | 2026-05-09 |
| 保留 external fallback tools | 父 RFC 要求 fallback；shell-native controls/headless 验证存在风险 | 一次性替换外部工具，风险较高 | 2026-05-09 |
| OSD 以 Quickshell-aware wrapper/IPC 方式接入 | 可以保留现有 media-key commands 和 rollback path | 直接删除 `hey .osd`，风险较高 | 2026-05-09 |
| 采用 shallow helper-backed controls | Headless 环境难以验证 deep DBus managers；Stage 3 first pass 更需要可靠 status + fallback | 一次性做完整 DBus control center，风险过大 | 2026-05-09 |

## 关键文件

**`.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md`** [contract]
- 作用: Stage 3 implementation task contract and design entrance。

**`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`** [source]
- 作用: Parent Stage 3 scope and acceptance source。

**`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/rfc.md`** [design]
- 作用: Stage 3 implementation design source of truth。

**`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-rfc.md`** [review]
- 作用: RFC review conclusion, current PASS。

**`config/quickshell/axiom-shell/shell.qml`** [future scope]
- 作用: Current Quickshell composition root with dock, notification panel and search panel。

**`config/hypr/hyprland.conf`** [future scope]
- 作用: Current media-key and quick-control bindings。

**`config/hypr/bin/osd.zsh` / `config/hypr/bin/osd.d/*.zsh`** [future scope]
- 作用: Current OSD behavior and volume/brightness actions。

**`config/quickshell/axiom-shell/QuickControlsPanel.qml`** [implementation]
- 作用: Stage 3 quick controls surface。

**`config/quickshell/axiom-shell/OsdOverlay.qml`** [implementation]
- 作用: Quickshell OSD overlay。

**`config/quickshell/axiom-shell/controls/axiom-control-helper.py`** [implementation]
- 作用: Fixed-verb status/actions helper for quick controls and media OSD。

**`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/test-report.md`** [verification]
- 作用: Stage 3 verification evidence, current PASS with runtime gaps。

**`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-change.md`** [review]
- 作用: Stage 3 readiness review, current PASS。

**`.legion/tasks/axiom-quickshell-quick-controls-osd/docs/report-walkthrough.md`** [delivery]
- 作用: Reviewer-facing delivery walkthrough。

**`.legion/wiki/tasks/axiom-quickshell-quick-controls-osd.md`** [wiki]
- 作用: Wiki task summary and current-truth entry。

## 快速交接

**下次继续从这里开始：**
1. Commit、fetch/rebase、push branch、创建 PR。
2. 尝试 auto-merge 并跟进 checks/review。
3. PR terminal 后 cleanup worktree 并 refresh main workspace。

---
*Updated: 2026-05-09*
