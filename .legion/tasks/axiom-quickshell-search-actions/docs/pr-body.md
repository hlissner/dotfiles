## Summary

- Adds the RFC Stage 2 Quickshell-owned search/action panel for apps, declared actions, web search, calculator, emoji, and clipboard history.
- Wires dock `APP` and `Super+Space` to Quickshell search while retaining Fuzzel fallback/direct access.
- Keeps execution bounded to fixed helper verbs/static argv actions and adds clipboard clear/disable/cap controls.

## Verification

- PASS: helper syntax and provider smoke for apps, calculator, emoji, web URL.
- PASS: isolated clipboard add/list/copy/clear/disabled smoke without touching the real clipboard.
- PASS: static safety checks, Nix parse/eval/build, and `Hyprland --verify-config`.
- PASS: change review found no blockers.

## Risks/Gaps

- Live Wayland/layer-shell behavior was not verified in this headless environment: panel focus, dock/IPC behavior, real app launch/copy/persistence, notification regression, and stopped-Quickshell fallback need Axiom session checks.
- Clipboard history intentionally persists user text; clear history and `modules.desktop.quickshell.search.clipboard.enable = false` are the privacy controls.
- `Super+Space` falls back on IPC command failure, but may not detect successful IPC followed by focus failure; direct Fuzzel remains on `Super+Shift+Space`.

## Rollback

- Revert this PR or switch to a previous NixOS generation.
- Minimal rollback: restore dock `APP` / `Super+Space` to direct `fuzzel` and disable the clipboard watcher.
- Clipboard cleanup: clear history, disable the clipboard option, stop `axiom-clipboard-history`, and remove `$XDG_STATE_HOME/axiom-shell/clipboard-history.json` if needed.
