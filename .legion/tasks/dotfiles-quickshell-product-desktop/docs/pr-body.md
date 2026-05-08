## Summary

- Replace Axiom's DMS/Rofi-first desktop surface with a repository-owned Quickshell product shell and visible Isabel-like side dock.
- Move Axiom Hyprland defaults toward a polished GUI-first desktop with rounded/gapped windows, blur/shadow, direct app/control/help bindings, and GUI-friendly rules.
- Add desktop onboarding docs and remove stale `config/ncmpcpp/**` payloads that contradict the new product direction.

## Verification

- `DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop" nix build --impure "path:/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop#nixosConfigurations.axiom.config.system.build.toplevel"`
- Targeted `nix eval` confirms `quickshell.service`, no `dms` user service, Rofi disabled for Axiom, Thunar enabled, Quickshell config linked, guide linked, and required GUI packages present.
- Generated full Hyprland config passes `Hyprland --verify-config`.
- Regression searches confirm no primary Hyprland `@rofi` / `dms ipc` / `dms run` references, no active module DMS service/IPC references, and no remaining `config/ncmpcpp/**` files.

## Deferred

- Live Quickshell rendering on Axiom hardware remains a post-deploy runtime check.
- Subjective visual refinements are deferred until the Isabel-aligned first pass is available to use.

## Evidence Docs

- `.legion/tasks/dotfiles-quickshell-product-desktop/docs/rfc.md`
- `.legion/tasks/dotfiles-quickshell-product-desktop/docs/test-report.md`
- `.legion/tasks/dotfiles-quickshell-product-desktop/docs/review-change.md`
- `.legion/tasks/dotfiles-quickshell-product-desktop/docs/report-walkthrough.md`
