# Review Change：Axiom Quickshell Notification Center

日期：2026-05-09
结论：PASS

## Blocking Findings

无。

## Scope Review

- PASS：实现仅触及 Axiom Quickshell shell source、任务证据和相关 Legion wiki/design evidence。
- PASS：没有修改 `modules/desktop/quickshell.nix`、`modules/desktop/hyprland.nix`、greetd、UWSM、portal、monitor、binding 或 fallback app ownership。
- PASS：实现聚焦 RFC Stage 1 notification center；scope grep 未发现 Stage 2 search/actions、clipboard persistence、dynamic theming、Rofi/DMS primary-shell 或 mutable upstream installer surface。
- PASS：复制 `dots-hyprland-desktop-rfc` 任务证据到本分支是可接受的交付补充，因为当前 base 缺少该 design source，而本实现合同直接依赖该 RFC。

## Correctness Review

- PASS：`NotificationServer` 继续作为接收入口，收到通知后设置 `tracked = true`，并基于 `trackedNotifications` 提供 session-local history。
- PASS：dock notification button 从 counter-only clear 行为改为 panel toggle，仍保留现有 side dock、launchers、workspace buttons、controls 和 clock。
- PASS：`NotificationPanel.qml` 显示来源、summary、body、group count、unread visual state、actions、dismiss 和 clear controls。
- PASS：review 前置审查发现并修复了 `ObjectModel.values.slice()` 兼容性风险；最终 clear flow 使用倒序索引 dismiss，不依赖未明确保证的 Array method。
- PASS：Nix build 通过，service eval 证明 `quickshell.service` 仍绑定 `hyprland-session.target`。

## Security And Privacy Lens

触发原因：notification body/history 可能包含敏感数据，属于 data exposure/privacy surface。

- PASS：notification history 只保留在 Quickshell runtime/session memory 中，没有新增 `PersistentProperties`、文件写入、clipboard persistence、cache persistence 或 external command execution。
- PASS：notification body 仅在用户打开 panel 时显示；本任务没有扩大到 search/actions arbitrary command surface。
- PASS with residual risk：headless 环境无法端到端验证 action invocation 和 dismiss/clear UI 行为；需要在真实 Axiom Hyprland session 中手测。

## Non-Blocking Notes

- 当前 grouping 是轻量 group count，而不是按 app 折叠 section；这符合本任务验收里的 `group counts`，后续可在通知量变大时再做折叠交互。
- 打开 panel 会把 unread count 标记为 seen，因此 panel 主要展示当前状态而不是保留“未读直到逐条点击”的 inbox 语义；这符合当前轻量产品切片。
- Quickshell smoke 在 offscreen/headless 环境停在 `No PanelWindow backend loaded`，这是验证环境限制，不是当前实现的阻塞问题。

## Verification Evidence Reviewed

- `.legion/tasks/axiom-quickshell-notification-center/docs/test-report.md`
- `git diff --cached --check` PASS
- targeted `nix eval` service ownership PASS
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` PASS
- headless/offscreen Quickshell smoke documented as expected limitation
