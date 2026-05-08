# Report Walkthrough: Quickshell Product Desktop

> Mode: implementation

## Reviewer Path

1. Start with the product contract in `plan.md` and `docs/rfc.md`: Axiom should become an Isabel-first Hyprland + Quickshell desktop, not a Rofi/DMS-first shortcut workstation.
2. Review shell ownership in `modules/desktop/quickshell.nix`: the default service now runs repository-owned `quickshell --config axiom-shell`, links `config/quickshell/axiom-shell`, installs GUI control dependencies, and restarts `quickshell.service` on reload.
3. Review the visible shell in `config/quickshell/axiom-shell/`: the left dock exposes workspace buttons, browser, terminal, files, chat, Steam, guide, app launcher, network, Bluetooth, audio, screenshot, recording, lock, power, clock, and notification status.
4. Review Axiom and Hyprland defaults in `hosts/axiom/default.nix`, `config/hypr/hyprland.conf`, `modules/desktop/hyprland.nix`, and `modules/themes/autumnal/hyprland.nix`: Rofi is no longer enabled by default, Thunar is enabled, Rofi/DMS binds are replaced on the primary path, and the compositor now uses Isabel-like gaps, rounding, blur, shadows, and GUI-friendly rules.
5. Review user-facing docs and cleanup: `docs/axiom-desktop.md` and `config/axiom-desktop/guide.md` document the visible UI and shortcut onboarding, while stale `config/ncmpcpp/**` payloads are removed.

## Evidence

- Design source: `docs/rfc.md`; RFC review PASS: `docs/review-rfc.md`.
- Verification evidence: `docs/test-report.md`.
- Readiness review: `docs/review-change.md` PASS.
- Implementation plan: `docs/implementation-plan.md`.

## Verification Summary

- PASS: Axiom `nix build` using explicit worktree `DOTFILES_HOME` and `path:` flake reference.
- PASS: targeted eval confirms `quickshell.service`, no `dms` user service, Rofi disabled, Thunar enabled, Quickshell config linked, guide linked, and required GUI packages present.
- PASS: generated full Hyprland config parses with `Hyprland --verify-config`.
- PASS: regression searches show no primary Hyprland `@rofi`, `dms ipc`, or `dms run` usage, no active module DMS service/IPC, and no remaining `config/ncmpcpp/**` payloads.

## Important Review Notes

- The build command must use `DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop"` and a `path:` flake reference in this nested worktree environment; the ambient `DOTFILES_HOME` previously pointed at an old Nix store source.
- A `.desktop` launcher validation failure was fixed by using a concrete guide path instead of shell quoting or `$HOME` in the desktop entry `Exec` field.
- A final review-prep polish removed an accidental duplicate `Super+D` launcher binding and added the visible `REC` recording control; build/eval/Hyprland/regression validation was rerun afterward.

## Residual Risks

- Live Quickshell rendering on Axiom hardware is not verified in this environment and remains a post-deploy runtime check.
- The first-pass shell is intentionally local and compact rather than a full import of Isabel's private framework; subjective visual refinements are expected after deployment.
