# Axiom Keybinding Help Modal

## Task Identity

- Name: Axiom Keybinding Help Modal
- Task ID: `axiom-keybinding-help-modal`
- Trigger: user asked whether `SUPER+/` can open a modal showing all keybindings.
- Risk: contained desktop feature

## Goal

Add an Axiom desktop shortcut that opens a modal-style keybinding reference for the current repo-generated Hyprland shortcuts.

## Problem

Axiom has many generated Hyprland shortcuts after the Caelestia migration and input configuration work. The keybinds are currently discoverable only by reading generated config or task notes. The user wants an in-session modal, preferably on `SUPER+/`, that shows the active shortcut map without changing existing shortcut behavior.

## Acceptance

- [ ] Generated Hyprland config binds `SUPER+/` to open the shortcut help surface.
- [ ] The help surface is a graphical modal/dialog suitable for the current GTK-themed desktop.
- [ ] The help content lists the current Axiom generated shortcuts, including the new help shortcut.
- [ ] Existing keybind command targets remain unchanged.
- [ ] The implementation stays in the Axiom Hyprland integration boundary and does not modify Caelestia shell source, Fcitx5, Rime, keyboard layout, wallpaper, or unrelated apps.
- [ ] Focused Nix evaluation, assembled Hyprland parser validation, and Axiom build/static checks prove the generated config shape.

## Assumptions / Constraints / Risks

- **Assumption**: `SUPER+/` should mean the slash keysym in Hyprland config, represented as `slash` while shown to users as `SUPER+/`.
- **Assumption**: A GTK `zenity --text-info` dialog is an acceptable modal-style help surface and will inherit the current GTK theme.
- **Constraint**: Keep this feature focused in generated Hyprland config; do not build a custom Caelestia drawer or Quickshell panel for this task.
- **Constraint**: Preserve canonical uppercase Hyprland modifier spelling.
- **Risk**: Static parser validation cannot prove the physical slash key opens the dialog in the live session; post-deploy smoke is still required.

## Scope

- `modules/desktop/hyprland.nix`
- `.legion/tasks/axiom-keybinding-help-modal/**`
- `.legion/wiki/**` closing writeback

## Non-Goals

- Do not redesign all keybind generation into a separate data model unless needed for this small feature.
- Do not add a Caelestia shell module or mutate upstream shell source.
- Do not change existing shortcut behavior beyond adding `SUPER+/`.
- Do not add search/filter UX beyond what the chosen text-info dialog already provides.

## Design Summary

- Generate a small `axiom-keybinding-help` script from Nix.
- Back the script with a repo-owned text file listing the current Axiom shortcuts.
- Launch the script from a new generated Hyprland bind: `bind = SUPER, slash, exec, <script>`.
- Use `zenity --text-info --modal` so the help opens as a graphical dialog matching the GTK theme.

## Phases

1. **Brainstorm** - Materialize the scoped feature contract.
2. **Engineer** - Add the generated help script/text and `SUPER+/` binding in the isolated worktree.
3. **Verify Change** - Run focused Nix evals, Hyprland parser validation, build/static checks, and record evidence.
4. **Review Change** - Read-only readiness review for scope, correctness, and maintainability.
5. **Report Walkthrough** - Generate reviewer-facing summary and PR body.
6. **Legion Wiki** - Write reusable task summary and maintenance note.

---

*Created: 2026-05-11 | Last updated: 2026-05-11*
