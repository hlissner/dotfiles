# Dotfiles Fcitx5 Wayland GTK IM Module

## Status
- Result: implemented and verified in PR branch worktree.
- Task docs: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/`

## Summary
This task makes the reusable Fcitx5 input module default to the native Wayland frontend whenever the managed desktop type is Wayland. The change addresses Fcitx5 diagnostics that recommend unsetting `GTK_IM_MODULE` when the Wayland frontend works, without removing GTK/Qt/Rime/Pinyin addon support or adding host-local shell workarounds.

## Current Outcome
- `modules.desktop.input.fcitx5.waylandFrontend` now defaults from `modules.desktop.type == "wayland"`.
- Axiom evaluates with `i18n.inputMethod.fcitx5.waylandFrontend = true`.
- Managed Axiom environment config does not export `GTK_IM_MODULE` through `environment.sessionVariables` or `environment.variables`.

## Evidence
- Verification: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/docs/test-report.md`
- Review: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/docs/review-change.md`
- Walkthrough: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/docs/report-walkthrough.md`

## Follow-up
- After deployment, run a live Wayland session smoke test in GTK applications to confirm text input behavior because static Nix evaluation cannot exercise toolkit runtime paths.
