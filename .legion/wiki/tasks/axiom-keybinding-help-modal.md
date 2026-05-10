# Axiom Keybinding Help Modal

## Metadata

- `task-id`: `axiom-keybinding-help-modal`
- `status`: `active`
- `risk`: `contained desktop feature`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task adds an Axiom `SUPER+/` shortcut reference feature. Generated Hyprland config now binds `SUPER, slash` to a repository-generated `axiom-keybinding-help` helper that opens a themed `zenity --text-info --modal` dialog.

The help content lists the current generated Axiom shortcut groups, including shell, Caelestia service, app/window, capture/clipboard, workspace, media/brightness, and reload shortcuts. Existing shortcut command targets remain unchanged, and the implementation stays inside `modules/desktop/hyprland.nix` plus task documentation.

Static validation passed for generated keybind assertions, Axiom toplevel build, realized helper/text inspection, assembled Hyprland parser validation, and diff whitespace. Live confirmation of the physical `SUPER+/` chord remains a post-deploy Hyprland-session smoke check.

## Reusable Decisions

- Axiom's in-session shortcut reference entrypoint is `SUPER+/`, represented in Hyprland config as keysym `slash`.
- Shortcut help content is repository-generated text and should be updated in the same task as future generated keybind changes.
- For simple shortcut reference UI, `zenity --text-info --modal` is the current implementation path; a custom Caelestia or Quickshell panel should require a separate feature task.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-keybinding-help-modal/plan.md`
- `log`: `.legion/tasks/axiom-keybinding-help-modal/log.md`
- `tasks`: `.legion/tasks/axiom-keybinding-help-modal/tasks.md`
- `test-report`: `.legion/tasks/axiom-keybinding-help-modal/docs/test-report.md`
- `review`: `.legion/tasks/axiom-keybinding-help-modal/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-keybinding-help-modal/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-keybinding-help-modal/docs/pr-body.md`

## Notes

- Post-deploy validation should press `SUPER+/` in the live Axiom Hyprland session and confirm the modal appears.
- If generated keybinds change, update `keybindingHelpText` alongside those bind changes.
