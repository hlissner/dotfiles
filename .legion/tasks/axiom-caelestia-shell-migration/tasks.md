# Tasks: axiom-caelestia-shell-migration

## Status

- Phase: wiki closeout complete; PR lifecycle required.
- Worktree: `.worktrees/axiom-caelestia-shell-migration/`
- Branch: `legion/axiom-caelestia-shell-migration`
- PR: pending.

## Checklist

- [x] Materialize task contract for replacing end4 with Caelestia shell.
- [x] Produce RFC for Caelestia package/module/service/Hyprland architecture.
- [x] Review RFC before implementation.
- [x] Open isolated git worktree and branch.
- [x] Add Caelestia flake input/package integration.
- [x] Replace end4-specific Quickshell service/module with Caelestia shell integration.
- [x] Simplify Hyprland config and preserve Nix-generated host facts.
- [x] Remove end4 vendored source/config/doc remnants from active repository source.
- [x] Run Nix/static validation and live-session checks where possible.
- [x] Complete readiness review.
- [x] Generate report walkthrough and PR body.
- [x] Write Legion wiki current-truth updates.
- [ ] Complete PR lifecycle, cleanup, and main workspace refresh.

## Open Decisions

- Chosen: keep a local NixOS integration module that consumes the upstream CLI-enabled Caelestia package; do not import the upstream HM module as primary architecture.
- Chosen: define Caelestia shell keybinds in Nix-generated host config using Caelestia global shortcut names and CLI-backed commands where appropriate.
- Completed: removed fuzzel/matugen and local quickshell source trees; no non-end4 active consumer remained.
