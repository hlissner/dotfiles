# Axiom Caelestia Keybind Fix

## Task Identity

- Name: Axiom Caelestia Keybind Fix
- Task ID: `axiom-caelestia-keybind-fix`
- Trigger: user reported Caelestia migration runtime regressions: Hyprland config parse failure from top-level `catchall`, plus icons showing as checkerboard placeholders with missing icon/MIME runtime package suspects.

## Goal

Restore Axiom Caelestia desktop usability by fixing the Hyprland generated-keybind parse error and ensuring Caelestia's icon/MIME runtime dependencies are exposed in the Nix-owned user environment.

## Problem

The Caelestia migration generated `bindin = Super, catchall, global, caelestia:launcherInterrupt` at top level. Hyprland rejects `catchall` outside submaps, so the generated keybind file prevents the active Hyprland configuration from loading cleanly. The shell also appears to be rendering checkerboard placeholder icons, consistent with missing icon-theme and MIME data packages in the active Caelestia runtime environment.

## Acceptance Criteria

- Generated `hypr/custom/keybinds.conf` no longer contains a top-level `catchall` keybind.
- Caelestia launcher, sidebar/session/lock, media, screenshot/record, clipboard, emoji, app, and workspace keybinds remain generated.
- Caelestia integration exposes the expected icon and MIME runtime packages: `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils`.
- Hyprland parser validation passes against an assembled Axiom config, or any unavailable parser surface is explicitly recorded.
- Nix evaluation/build evidence covers the generated keybind file, Caelestia package closure exposure, and Axiom desktop configuration.
- Legion verification, review, walkthrough, wiki closeout, and PR lifecycle evidence are recorded.

## Assumptions

- The reported line maps to the Nix-generated `modules.desktop.hyprland` keybind block from the Caelestia migration.
- Removing the invalid `catchall` interrupt bind is safer than adding a submap because no Caelestia submap behavior was designed in the migration.
- Mouse interrupt binds are still valid top-level Hyprland bindings unless validation proves otherwise.
- The checkerboard icons are caused by missing icon-theme/MIME data exposure rather than an upstream Caelestia rendering bug.

## Constraints

- Do not reintroduce end4, legacy Quickshell, fuzzel fallback, or `quickshell --config ii` paths.
- Do not expand the task into a broader Caelestia keybind redesign.
- Do not redesign GTK/theme ownership beyond adding Caelestia runtime dependencies.
- Keep Darwin isolated from Linux desktop changes.
- Preserve repository-owned generated Hyprland host facts.

## Scope

- Update the generated Axiom Hyprland keybind source to avoid invalid top-level `catchall` syntax.
- Add the Caelestia README-style icon/MIME runtime packages to the local Caelestia module's Linux user package exposure.
- Add focused validation evidence for the generated keybind text and Hyprland config parser.
- Record the hotfix in Legion task docs and wiki.

## Non-Goals

- Do not change Caelestia upstream shell code.
- Do not redesign global shortcut mappings beyond the reported parse error.
- Do not change the selected GTK icon theme or visual design.
- Do not perform live graphical behavior validation unless a Hyprland session is available.
- Do not remove unrelated historical Legion references to end4.

## Design Summary

- Treat this as a low-risk syntax hotfix to the Nix-generated Hyprland keybind block.
- Remove the top-level `bindin = Super, catchall, ...` line and keep explicit mouse interrupt bindings plus the normal Caelestia launcher binding.
- Add common icon theme and MIME packages beside the Caelestia shell/CLI packages so Qt/desktop icon lookup has standard fallback data.
- Verify with direct Nix eval of generated keybinds, user packages, and an assembled `Hyprland --verify-config` run when possible.

## Risks

- Removing the `catchall` interrupt may reduce launcher interruption behavior for some keyboard sequences, but it is better than preventing Hyprland config parsing.
- Icon checkerboards could also involve upstream Caelestia icon lookup behavior, so package exposure may still require live session confirmation.
- Hyprland parser validation may expose other migration-time syntax issues that were not caught by Nix build alone.
- Headless validation still cannot prove Caelestia launcher focus or visual behavior.

## Phases

- Brainstorm: materialize this focused hotfix contract.
- Engineer: patch generated keybind syntax and Caelestia icon/MIME runtime package exposure in the isolated worktree.
- Verify Change: run focused Nix and Hyprland parser validation.
- Review Change: assess readiness and scope.
- Report Walkthrough: generate reviewer-facing summary and PR body.
- Legion Wiki: update current maintenance/pattern notes if needed.
- PR Lifecycle: commit, push, create PR, follow checks/review, clean worktree, and refresh main workspace.
