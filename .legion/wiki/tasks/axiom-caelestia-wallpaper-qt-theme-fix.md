# Axiom Caelestia Wallpaper Qt Theme Fix

## Metadata

- `task-id`: `axiom-caelestia-wallpaper-qt-theme-fix`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task follows the first Caelestia wallpaper/launcher fix. After Caelestia became the only wallpaper owner, live logs showed `/home/c1/the-great-sage.jpg` was still rejected by Qt image IO because its decoded allocation slightly exceeded the default `256 MB` limit. The implementation keeps that file as the canonical host wallpaper source but makes the Caelestia service pre-start script generate a decode-safe derivative at `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` using ImageMagick bounded to `3840x2160`.

The seed logic preserves manual user choice: it only rewrites `path.txt` when the state file is missing, empty, or still points at the oversized canonical source. It does not restore `swaybg` or change the prior Caelestia wallpaper ownership decision.

The task also applied the upstream `caelestia-dots/shell#1282` icon-block workaround by setting `QT_QPA_PLATFORMTHEME=qt6ct` in the Caelestia service, generated Hyprland env, generated UWSM env, Hyprland session variables, and systemd user import hook. That Qt-theme workaround is now historical: `axiom-caelestia-readme-alignment` superseded it for the current new-machine setup with README-aligned `qtengine`.

Validation passed for targeted generated Nix values, the Axiom NixOS toplevel build, and an ImageMagick smoke test that converted the source wallpaper to `3840x1858 757392B`. Live validation remains required after deployment and Hyprland restart for graphical icon rendering and actual Caelestia wallpaper display.

## Reusable Decisions

- Keep Caelestia as Axiom's wallpaper owner; do not restore `swaybg` for this host while `modules.desktop.caelestia.wallpaper.enable = true`.
- For oversized host-local wallpaper sources, prefer a decode-safe Caelestia runtime derivative over raising Qt image allocation limits globally.
- Historical note: the issue #1282 `qt6ct` workaround from this task was superseded by `axiom-caelestia-readme-alignment`; current Axiom Caelestia uses `QT_QPA_PLATFORMTHEME=qtengine` unless a future live-regression task reopens the color-block issue.
- Preserve user-selected Caelestia wallpaper state; seed or correct `path.txt` only for missing/empty state or the known oversized canonical source.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/tasks.md`
- `rfc`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/pr-body.md`

## Notes

- A full Hyprland restart is required to validate the `QT_QPA_PLATFORMTHEME=qt6ct` launcher icon workaround for newly started processes.
- After deployment, confirm `path.txt` points at `generated.jpg` unless the user selected a different wallpaper, Caelestia logs no longer show the Qt allocation rejection, no `swaybg` process is active, one Caelestia quickshell instance is active, and launcher icons render normally.
