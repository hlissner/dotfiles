# Report Walkthrough

## Mode
implementation

## Summary
- Default the reusable Fcitx5 module to `waylandFrontend = true` whenever the managed desktop type is Wayland.
- This lets NixOS/Fcitx5 use the native Wayland input method frontend and avoids exporting `GTK_IM_MODULE` through managed environment variables.
- The change preserves existing GTK/Qt/Rime/Pinyin addon configuration and avoids host-local shell workarounds.

## Files Changed
- `modules/desktop/input/fcitx5.nix`: adds a module-level `mkDefault` for `waylandFrontend` based on `modules.desktop.type == "wayland"`.
- `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/**`: records contract, verification, review, and delivery evidence.

## Validation Evidence
- `docs/test-report.md` records PASS for focused Axiom Nix evaluation.
- Axiom evaluates with `i18n.inputMethod.fcitx5.waylandFrontend = true`.
- Managed environment checks show `GTK_IM_MODULE` absent from both `environment.sessionVariables` and `environment.variables`.
- Axiom system toplevel evaluation produced a valid derivation path.

## Review Evidence
- `docs/review-change.md` records PASS with no blocking findings.
- Residual risk is limited to post-rebuild live GTK application smoke testing.

## Notes For Reviewer
- The implementation intentionally relies on the existing NixOS Fcitx5 Wayland frontend option instead of manually unsetting variables.
- Explicit host overrides remain possible because the new value is an `mkDefault`.
