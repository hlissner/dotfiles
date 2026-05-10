# Axiom Fcitx5 Shell Theme Alignment

## Metadata

- `task-id`: `axiom-fcitx5-shell-theme-alignment`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task aligns Axiom's Fcitx5 classic UI with the current Autumnal/Graphite pink shell accent. Axiom now selects `catppuccin-mocha-pink` instead of inheriting the module default `catppuccin-mocha-mauve`.

The change is host-level only: Rime, Pinyin/Chinese addons, force-managed user `fcitx5/conf/classicui.conf`, and the reusable Fcitx5 module API remain unchanged. Static validation passed for evaluated Fcitx5 settings, generated user config, addon preservation, Hyprland parser config, and Axiom toplevel build.

## Reusable Decisions

- For Axiom's Autumnal/Graphite pink desktop, Fcitx5 should use `catppuccin-mocha-pink` unless a future theme task changes the shell accent.
- Fcitx5 color alignment should use the existing `modules.desktop.input.fcitx5.theme.accent` option before creating custom theme packages.
- Live visual confirmation still requires restarting Fcitx5 or the user session after deployment.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/plan.md`
- `log`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/log.md`
- `tasks`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/tasks.md`
- `test-report`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/docs/test-report.md`
- `review`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-fcitx5-shell-theme-alignment/docs/pr-body.md`

## Notes

- Post-deploy validation should confirm the candidate window visually uses the pink accent after restarting Fcitx5 or the graphical session.
