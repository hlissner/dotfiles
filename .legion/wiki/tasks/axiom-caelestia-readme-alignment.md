# Axiom Caelestia README Alignment

## Metadata

- `task-id`: `axiom-caelestia-readme-alignment`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `axiom-caelestia-wallpaper-qt-theme-fix` qt6ct workaround only
- `superseded-by`: `(none)`

## Outcome Summary

This task aligns Axiom's Caelestia desktop with the upstream README-style setup for a new Caelestia machine. The current effective configuration uses Thunar as the Finder-like explorer, Rubik/Material Symbols/Caskaydia Cove font families in Caelestia shell settings, FiraCode Nerd Font Mono in Foot, and CJK fontconfig fallbacks for Chinese sans/mono coverage.

The current Qt platform theme decision is `QT_QPA_PLATFORMTHEME=qtengine`, not the earlier `qt6ct` workaround. `qtengine` is provided by a locked `kossLAN/qtengine` flake input and wired through the Caelestia service, session variables, generated Hyprland env, and generated UWSM env.

The task also imports Autumnal Hyprland styling and sets Caelestia-like rounded windows. Static validation passed with focused Nix evals, generated Hyprland `--verify-config` against configured Hyprland 0.53.3, and the Axiom NixOS toplevel build.

## Reusable Decisions

- For current Axiom Caelestia work, prefer upstream README-aligned `qtengine`; treat the older `qt6ct` launcher workaround as historical unless a future live-session regression proves it is needed again.
- Keep Caelestia shell overrides minimal. Set durable host policy such as `appearance.font.family`, `background.wallpaperEnabled`, launcher dangerous-action policy, and app defaults, but do not copy the full upstream example `shell.json`.
- Use Thunar as the Finder-like explorer for Caelestia because the upstream README and optional dependencies point to `thunar`; enable GVFS for file-manager functionality.
- Put shared font policy in the theme/fontconfig layer, while exposing Caelestia-specific family names through shell settings and deriving Foot's default font from `modules.theme.fonts.terminal`.
- For Hyprland 0.53 validation, use the configured package from `config.programs.hyprland.package` and assembled generated config; do not rely on an incidental `nixpkgs#hyprland` version.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-readme-alignment/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-readme-alignment/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-readme-alignment/tasks.md`
- `test-report`: `.legion/tasks/axiom-caelestia-readme-alignment/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-readme-alignment/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-readme-alignment/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-readme-alignment/docs/pr-body.md`

## Notes

- Live visual validation still requires deploying Axiom, restarting Hyprland, and relaunching relevant apps.
- Static validation proves generated font package/fallback declarations, not final rendered glyph selection in every toolkit.
