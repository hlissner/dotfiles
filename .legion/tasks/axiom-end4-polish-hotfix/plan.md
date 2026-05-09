# Axiom End4 Polish Hotfix

## Task Identity

- Name: Axiom End4 Polish Hotfix
- Task ID: `axiom-end4-polish-hotfix`
- Trigger: user reports remaining live regressions after the end4 `ii` import became visually close: `Super+Space` opens a black, non-responsive box; network/Bluetooth icons render as checkerboards; `Ctrl+Super+T` image preview renders checkerboards; end4 preset wallpapers cannot be applied and the expected theme color switch is not visible. User also wants the end4 dock enabled and placed on the far left.
- Base ref: `origin/master`

## Goal

Make the imported end4 `ii` desktop feel usable for the reported interaction and visual polish paths without rolling back to the legacy shell. The primary launcher/search entrypoint should accept input, status icons should render through available icon fonts or assets, screenshot/image preview should show actual images rather than checkerboard placeholders, the end4 wallpaper selector should apply preset wallpapers with the expected theme-color regeneration path, and the end4 dock should be enabled on the left edge by default.

## Problem

The previous end4 integration fixed the main shell load path but left smaller live regressions around input focus, font/icon coverage, and image preview rendering. These issues are likely in Axiom's Nix-owned wrapper/runtime dependencies, generated Hyprland bindings, or imported end4 runtime assumptions rather than reasons to replace end4 `ii` with the old shell.

## Acceptance Criteria

- `Super+Space` opens the intended end4 launcher/search entrypoint and typed input reaches the field.
- Network and Bluetooth status icons no longer render as black-white checkerboards due to missing font glyphs or icon resources.
- `Ctrl+Super+T` image preview shows real image content instead of checkerboard placeholders for valid screenshots/images.
- End4 preset wallpapers can be selected through the wallpaper UI, and selection triggers the repository-owned theme color generation/reload path.
- The end4 dock is enabled by default and positioned on the far left edge.
- Fixes keep end4 `ii` as the active shell and do not restore the legacy Axiom shell as the primary path.
- Nix remains the owner of runtime packages, wrapper environment, generated Hyprland overrides, and host-specific integration.
- Repository-local validation covers generated config/package evidence; any live-session limits are recorded.

## Scope

- Inspect imported end4 `ii` launcher/search, status icon, wallpaper selector/theme, dock, and image preview paths.
- Inspect generated Hyprland bindings and Quickshell wrapper/runtime dependencies relevant to the three reported symptoms.
- Patch the minimal repository-owned Nix/config/import surface needed to restore the reported behavior.
- Record verification evidence, residual live validation, review result, walkthrough, and wiki writeback.

## Non-Goals

- Do not roll back the complete end4 import.
- Do not redesign the launcher, dock, quick settings, network/Bluetooth UI, wallpaper workflow, or screenshot workflow beyond the reported regressions and requested placement.
- Do not vendor generated state, caches, secrets, or live home mutation artifacts.
- Do not change Darwin behavior or unrelated shell/dev modules.

## Assumptions

- The issue is on the `axiom` Linux workstation after applying the end4 import and previous regression hotfix.
- The black-white checkerboard symptom may indicate missing font glyph coverage, missing image provider/plugin support, missing asset paths, or invalid QML image source handling; implementation should confirm rather than assume.
- Live graphical validation may be limited from the tool shell, so static/package checks plus any available session logs are acceptable evidence if live UI cannot be exercised directly.

## Constraints

- Use the Legion worktree/PR lifecycle for repository modifications.
- Preserve NixOS ownership of runtime dependencies and generated config boundaries.
- Keep changes minimal and scoped to end4 `ii` integration polish.
- Do not mutate live `~/.config` outside repository/Nix ownership.

## Risks

- Quickshell/QML image preview failures may require a runtime plugin or provider not obvious from static source inspection.
- Icon checkerboards can come from font fallback, Material Symbols, Nerd Font, or asset resolution; fixing only one layer may not cover all surfaces.
- `Super+Space` may open an unfocused or hidden input because of Hyprland focus/window rules rather than only the IPC binding.

## Design Summary

- Treat the three symptoms as incomplete end4 runtime integration, not as a product-direction change.
- Prefer adding missing runtime dependencies, font packages, wrapper environment paths, and host-level generated overrides over editing imported upstream source.
- If imported end4 code has an Axiom-specific path assumption, patch the repository-owned import minimally and document why it is local integration glue.
- Validate through targeted source checks, Nix evaluation/builds where practical, generated config inspection, and available user-session logs.

## Phases

- Brainstorm: materialize this confirmed low-risk hotfix contract.
- Engineer: inspect the launcher/input, icon/font, and image preview paths and apply minimal fixes.
- Verify: run targeted eval/build/static checks and record live-session limits.
- Review: perform readiness review against scope and regressions.
- Report/wiki: generate reviewer-facing walkthrough and update Legion wiki current truth/backlog.
