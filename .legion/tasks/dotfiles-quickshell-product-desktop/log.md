# Log

## 2026-05-08

- User requested Legion workflow and challenged whether the current code truly matches the previous markdown claims about hlissner architecture cleanup and deletion of obsolete desktop paths.
- Restored context from prior tasks: `dotfiles-wayland-product-overhaul`, runtime followups, visible-shell fix, and wiki decisions.
- Re-cloned hlissner upstream snapshot at `1b4383a` and confirmed the local code broadly follows the hlissner cleanup direction for active Nix desktop paths: no active bspwm/sxhkd/Waybar/Dunst desktop modules were found, Hyprland uses UWSM, and old X11 desktop type is asserted out.
- Found mismatch between previous task wording and current tree: `config/ncmpcpp/` still exists locally while hlissner's current snapshot no longer carries it. It appears stale and should be cleaned if still unreferenced.
- Re-cloned Isabel upstream at `b9c5f08`. The visible reference screenshot and Hyprland config show the intended product feel: persistent side shell/dock/status surface, rounded/gapped Hyprland, common GUI app bindings, and discoverable desktop behavior.
- User clarified the decisive product requirement: desktop experience must at least completely align with Isabel first; the user will adjust disliked parts later. It is acceptable to discard hlissner desktop configuration, including Rofi, and backward compatibility must not constrain the solution.
- User added validation requirement: after implementation, `nix build` must pass.
- Created PR worktree `.worktrees/dotfiles-quickshell-product-desktop` on branch `legion/dotfiles-quickshell-product-desktop` from `origin/master`.
- Wrote task contract plus Heavy RFC/research/implementation-plan and recorded RFC review PASS.
- Implemented first product pass: local `quickshell.service` runs repository-owned `config/quickshell/axiom-shell`, Axiom no longer enables Rofi, Thunar is enabled, DMS service ownership was removed, Hyprland keybindings no longer call Rofi/DMS on the primary path, Isabel-like gaps/rounding/blur/shadow defaults were applied, `docs/axiom-desktop.md` documents visible controls and shortcut onboarding, and stale `config/ncmpcpp/` payloads were removed.
- Targeted eval passed for the first implementation check: Axiom has `quickshell.service`, no `dms` user service, Rofi disabled, Thunar enabled, Quickshell config linked, and desktop guide linked.
- Verification passed. Required Axiom `nix build` succeeded using explicit worktree `DOTFILES_HOME` and `path:` flake reference; targeted eval, Hyprland `--verify-config`, and regression searches also passed. Recorded details in `docs/test-report.md`.
- During readiness prep, removed an accidental duplicate `Super+D` launcher binding so it remains the existing screen drawing shortcut, added a visible `REC` screen recording control to the Quickshell shell and guide, reran build/eval/Hyprland/regression validation successfully, and recorded change review PASS in `docs/review-change.md`.
- Created implementation-mode reviewer walkthrough and PR body in `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed wiki writeback with a task summary, updated current desktop decision, and recorded the nested worktree validation pattern.
