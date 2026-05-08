# Dotfiles Quickshell Product Desktop

Status: PR-ready implementation handoff
Task: `.legion/tasks/dotfiles-quickshell-product-desktop/`
Branch: `legion/dotfiles-quickshell-product-desktop`

## Summary

Reworked Axiom's desktop target from a DMS/Rofi-first Hyprland setup into an Isabel-first Hyprland + repository-owned Quickshell product desktop. The new default surface is a visible side dock with workspace, app, control, guide, screenshot, recording, lock, power, clock, and notification-status affordances.

## Effective Outcome

- Axiom uses `quickshell.service` to run local `config/quickshell/axiom-shell` through the `axiom-quickshell` package wrapper.
- Axiom no longer enables Rofi by default, and the primary Hyprland path no longer calls `@rofi`, `dms ipc`, or `dms run`.
- Hyprland defaults now favor the Isabel-like product feel: gaps, rounded corners, blur, shadows, polished borders, and GUI-friendly app/control/window rules.
- The user-facing guide exists both in repository docs and as a linked runtime config at `~/.config/axiom-desktop/guide.md`.
- Stale `config/ncmpcpp/**` payloads were removed because they contradicted the current desktop cleanup direction and were unreferenced.

## Validation

- Axiom `nix build` passed using explicit worktree `DOTFILES_HOME` and a `path:` flake reference.
- Targeted eval passed for Quickshell service/config, no DMS user service, Rofi disabled, Thunar enabled, guide linked, and GUI packages present.
- Generated full Hyprland config passed `Hyprland --verify-config`.
- Regression searches passed for removed primary Rofi/DMS paths and absent `config/ncmpcpp/**`.
- Change review PASS and implementation-mode walkthrough/PR body were produced.

## Residual Risks

- Live Quickshell rendering on Axiom hardware is deferred until deployment.
- Visual taste refinements are expected after the Isabel-aligned first pass is available.

## Related Raw Sources

- Plan: `.legion/tasks/dotfiles-quickshell-product-desktop/plan.md`
- RFC: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/rfc.md`
- RFC review: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/review-rfc.md`
- Test report: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/test-report.md`
- Change review: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/review-change.md`
- Walkthrough: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/report-walkthrough.md`
