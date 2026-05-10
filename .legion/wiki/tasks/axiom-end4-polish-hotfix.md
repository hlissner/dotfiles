# Axiom End4 Polish Hotfix

## Metadata

- `task-id`: `axiom-end4-polish-hotfix`
- `status`: `historical`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `true`
- `supersedes`: `(none)`
- `superseded-by`: `axiom-caelestia-shell-migration`

## Outcome Summary

This hotfix is historical. It kept the imported end4 `ii` shell active at the time and fixed the remaining reported polish paths after the first end4 regression fix. The patch routed `Super+Space` through a dedicated `startMenu` IPC before fallback search/Fuzzel, gave launcher/overview layer-shell windows exclusive keyboard focus, replaced broken `TEST_ALIVE` fallback probes with a no-op `shell alive` IPC, and expanded the Quickshell user service PATH with the runtime tools end4 helpers expected.

Wallpaper and preview paths now stay inside XDG cache/state boundaries, expose the imported end4 preset wallpapers in the selector, and ensure generated color/wallpaper directories exist before theme regeneration. The end4 dock is enabled and pinned by default, with a one-time Axiom migration for existing user config, and the existing bottom dock is left-aligned to the far-left screen edge.

Repository-local validation passed, including diff hygiene, targeted static checks, Nix evals for generated Hyprland config and Quickshell service ownership, full Axiom toplevel build, and readiness review. Live graphical confirmation remains required for final behavior because this environment cannot exercise keyboard focus, icon/image rendering, wallpaper application, or dock placement in the running Hyprland session.

## Reusable Decisions

- Historical only: end4 `ii` was the product truth for this desktop before `axiom-caelestia-shell-migration`; current work should use Caelestia Shell instead.
- Host-level primary launcher bindings may try a dedicated end4 IPC target first, then broader search IPC, then external fallback, as long as Nix owns the generated Hyprland override.
- Imported Hyprland fallback probes should call an actual no-op Quickshell IPC function such as `shell alive`; placeholder targets like `TEST_ALIVE` are not valid liveness checks.
- Quickshell services started by systemd need an explicit Nix-owned PATH for helper binaries used by imported QML/process code, including network, Bluetooth, clipboard, image, wallpaper, and theme-generation tools.
- Imported shell temp media paths should prefer XDG cache/state over shared `/tmp` paths unless a task explicitly designs cross-process temporary storage.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-end4-polish-hotfix/plan.md`
- `log`: `.legion/tasks/axiom-end4-polish-hotfix/log.md`
- `tasks`: `.legion/tasks/axiom-end4-polish-hotfix/tasks.md`
- `test-report`: `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-end4-polish-hotfix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-end4-polish-hotfix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-end4-polish-hotfix/docs/pr-body.md`

## Notes

- Post-deployment validation should restart or reload `quickshell.service`, press `Super+Space` and type into the launcher, inspect network/Bluetooth icons, preview screenshot/image content, apply an end4 preset wallpaper and confirm theme regeneration, and confirm the dock is pinned at the far-left edge.
