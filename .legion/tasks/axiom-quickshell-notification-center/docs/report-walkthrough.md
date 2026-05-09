# Walkthrough：Axiom Quickshell Notification Center

> 模式：implementation
> 任务：`.legion/tasks/axiom-quickshell-notification-center/`
> 设计来源：`.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md`

## Reviewer Summary

- Implements RFC Stage 1 only: Axiom's Quickshell notification entry is upgraded from counter-only state to a visible session-local notification center.
- Preserves existing Nix/UWSM/Hyprland ownership: no service target, startup, portal, monitor, fallback app, or host module changes.
- Adds `NotificationPanel.qml` as the focused UI component for notification history, app/source counts, unread state, body rendering, action buttons, dismiss, and clear flows.
- Carries forward the design-only RFC task evidence because the current base branch did not contain the referenced Legion design source.

## What Changed

- `config/quickshell/axiom-shell/shell.qml`
  - Switches notification count from a manual counter to `NotificationServer.trackedNotifications`.
  - Adds session-local unread key tracking and panel toggle state.
  - Keeps `NotificationServer` as the only notification ingress and continues to mark notifications as tracked.
  - Changes the dock notification button from clear-on-click to panel toggle.
  - Adds a second `PanelWindow` next to the side dock for notification details.
- `config/quickshell/axiom-shell/NotificationPanel.qml`
  - Displays current-session notifications with sender name, summary, body, group count, unread marker, action buttons, dismiss, and clear.
  - Uses plain-text body rendering and no persistence.
- `.legion/tasks/axiom-quickshell-notification-center/**`
  - Adds implementation contract, log, verification report, and review result.
- `.legion/tasks/dots-hyprland-desktop-rfc/**` and related wiki entries
  - Adds the approved RFC/design evidence that this implementation depends on.

## Scope Boundaries

- In scope: RFC Stage 1 Shell State and Notification Center.
- Out of scope: shell search/actions, clipboard history, quick settings, OSD, dynamic theming, AI/cloud/OCR/translation, Hyprland/session rewiring, and persistent notification storage.
- Fallback tools such as Fuzzel, Blueman, NetworkManager editor, Pavucontrol, Wlogout, screenshot, record, lock, and power commands remain available.

## Verification

Evidence: `.legion/tasks/axiom-quickshell-notification-center/docs/test-report.md`

- `git diff --cached --check`: PASS.
- Targeted `nix eval` for Quickshell service ownership: PASS; service still uses `axiom-shell` and `hyprland-session.target` for `wantedBy`, `after`, and `partOf`.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS.
- Scope grep for Stage 2/search/clipboard/dynamic-theme/Rofi/DMS QML surface: PASS, no matches.
- Headless/offscreen Quickshell smoke: expected limitation, stops at `No PanelWindow backend loaded`; no full layer-shell runtime is available in this environment.

## Review Result

Evidence: `.legion/tasks/axiom-quickshell-notification-center/docs/review-change.md`

- Result: PASS, no blocking findings.
- Security/privacy lens applied because notification bodies may contain sensitive data.
- Risk accepted because the implementation does not persist notification history or introduce arbitrary command/search/clipboard surfaces.

## Residual Risks

- Real notification receipt, action invocation, dismiss, and clear behavior still need Axiom Hyprland session testing.
- Grouping is currently count-only rather than collapsible grouped sections.
- Opening the panel marks current unread notifications as seen; stronger inbox semantics are deferred.

## Rollback

- Before merge: revert this PR.
- After deployment: revert the NixOS generation or restore the previous counter-only `shell.qml` behavior.
- If only Quickshell fails at runtime: stop/restart `quickshell.service`; Hyprland keybindings and external fallback tools remain available.
