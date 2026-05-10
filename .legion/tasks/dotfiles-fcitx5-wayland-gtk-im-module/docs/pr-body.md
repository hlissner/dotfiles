## Summary
- Default Fcitx5 to its Wayland frontend on managed Wayland desktop hosts.
- Avoid the `GTK_IM_MODULE` Wayland warning by relying on the native Fcitx5 frontend instead of a host-local environment workaround.
- Preserve existing Fcitx5 addon configuration and explicit override behavior.

## Validation
- `nix eval ".#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.waylandFrontend"`
- `nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in { session = builtins.hasAttr "GTK_IM_MODULE" cfg.environment.sessionVariables; variables = builtins.hasAttr "GTK_IM_MODULE" cfg.environment.variables; }'`
- `nix eval ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`

## Evidence
- Legion plan: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/plan.md`
- Test report: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/docs/test-report.md`
- Review: `.legion/tasks/dotfiles-fcitx5-wayland-gtk-im-module/docs/review-change.md`
