# Axiom End4 Regression Fix

## Task Identity

- Name: Axiom End4 Regression Fix
- Task ID: `axiom-end4-regression-fix`
- Trigger: user reported PR #19 broke the left sidebar / `Super+Space` path and Axiom's Colemak keyboard layout, then clarified the primary goal remains complete end4 import rather than a narrow fallback repair.
- Base ref: `origin/master`

## Goal

Make the complete end4 import actually usable on Axiom. The imported `ii` shell must start successfully, its launcher/sidebar hotkeys must be reachable, and the configured Colemak keyboard layout must be applied in Hyprland. This is a completion fix for end4 integration, not a rollback to the old shell.

## Problem

The complete end4 import replaced the active Hyprland and Quickshell runtime path. Live logs show `quickshell.service` is failing to load imported `ii` because a required QML module is unavailable, which explains missing shell surfaces. The import also dropped or failed to apply Axiom-specific host overrides that previously made `Super+Space` useful and applied host keyboard layout facts. The user can still use `Super+Enter`, so Hyprland is running, but end4 shell loadability, keybind coverage, and input configuration are incomplete.

## Acceptance Criteria

- Imported end4 `ii` starts without the observed missing-QML-module failure.
- `Super+Space` is bound to a working end4 launcher, overview, or sidebar entrypoint.
- Axiom keyboard layout facts restore Colemak behavior through generated Hyprland input config.
- The fix keeps end4 `ii` as the active shell; it must not roll back to legacy `axiom-shell` or hide the failure behind a substrate-only fallback.
- Nix remains the owner of host-specific hotkeys and input facts.
- Logs or generated config evidence identify the failure mode clearly enough for the task record.
- Targeted Nix evaluation/build or static validation passes.

## Scope

- Inspect current user-session logs where available.
- Inspect generated Hyprland/Quickshell config and imported end4 QML/runtime/keybind expectations.
- Patch Nix-generated Hyprland overrides or Quickshell service integration where needed for complete end4 runtime loadability and the reported regressions.
- Record verification and residual live-session steps.

## Non-Goals

- Do not revert the complete end4 import.
- Do not redesign the end4 UI or remove upstream `ii` surfaces.
- Do not solve all upstream optional command compatibility issues.
- Do not mutate live home config outside Nix/repository ownership.

## Assumptions

- The current complaint is about the post-PR #19 runtime on Axiom.
- The tool shell may still be TTY; live graphical validation depends on session availability.
- A minimal Nix/Hyprland/Quickshell integration fix is preferable to broad rewrites, but the imported end4 shell must actually load.

## Constraints

- Use the Legion worktree/PR lifecycle.
- Preserve NixOS ownership of host facts and generated-state boundaries.
- Do not touch unrelated untracked files such as the main-workspace `end4.md`.

## Risks

- Without a live Wayland session, we may need to validate static/generated config and rely on the user to switch/reload.
- End4 keybinds may expect Quickshell IPC names that differ from Axiom's intended shortcuts.
- Hyprland input syntax changes can silently fail if generated in the wrong layer.

## Design Summary

- Treat missing QML/runtime dependencies as incomplete end4 import wiring, not as optional polish.
- Treat hotkeys and keyboard layout as Axiom host overrides layered on top of imported end4 defaults.
- Prefer generated Hyprland `custom/*.conf` changes over editing imported upstream source.
- Verify through evaluated/generated config text, targeted build, and logs when available.

## Phases

- Restore/brainstorm: materialize this narrow regression contract.
- Engineer: inspect logs/config and patch the minimal end4 runtime and generated override paths.
- Verify: run targeted eval/build/static checks and record live-session limits.
- Review/report/wiki: document readiness and ship via PR lifecycle.
