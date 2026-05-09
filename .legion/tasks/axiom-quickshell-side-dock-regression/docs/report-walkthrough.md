# Walkthrough：Axiom Quickshell Side Dock Regression

> 模式：implementation
> 任务：`.legion/tasks/axiom-quickshell-side-dock-regression/`

## Summary

- Fixes the PR #14 regression where the left side dock disappeared after adding the notification panel.
- Root cause: the dock `PanelWindow` and notification `PanelWindow` were siblings inside the same `Variants`, which made the per-screen delegate structure unreliable.
- Fix: close the dock `Variants` after the dock panel, then create a second `Variants` for the notification panel.

## Changed Files

- `config/quickshell/axiom-shell/shell.qml`
  - Keeps the side dock as the only `PanelWindow` inside the first `Variants`.
  - Moves the notification panel into its own `Variants` with the same `Quickshell.screens` model.
  - Leaves notification center state/action/dismiss/clear logic unchanged.
- `.legion/tasks/axiom-quickshell-side-dock-regression/**`
  - Adds contract, verification report, review, walkthrough, and PR body evidence.

## Validation

Evidence: `.legion/tasks/axiom-quickshell-side-dock-regression/docs/test-report.md`

- `git diff --cached --check`: PASS.
- QML structure grep: PASS, now two `Variants` and two `PanelWindow` entries in separate blocks.
- Quickshell service ownership eval: PASS, still bound to `hyprland-session.target`.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS.
- Headless/offscreen Quickshell smoke: expected limitation, no `PanelWindow` backend in this environment.

## Review

Evidence: `.legion/tasks/axiom-quickshell-side-dock-regression/docs/review-change.md`

- Result: PASS, no blocking findings.
- Security boundary unchanged.

## Residual Manual Check

- In the real Axiom Hyprland session, restart `quickshell.service` or reload the desktop and confirm the left side dock is visible.
- Click the notification dock button and confirm the notification panel still toggles.
