# Axiom Caelestia Shell Migration

## Metadata

- `task-id`: `axiom-caelestia-shell-migration`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `dots-hyprland-desktop-rfc`, `axiom-end4-regression-fix`, `axiom-end4-polish-hotfix`
- `superseded-by`: `(none)`

## Outcome Summary

Axiom's current desktop shell direction is Caelestia Shell, not the previous vendored end4 `ii` product path. The implementation consumes `caelestia-dots/shell` through the upstream Nix flake `with-cli` package, adds a local `modules.desktop.caelestia` integration module, writes minimal Nix-owned `caelestia/shell.json`, and starts `caelestia-shell.service` under `hyprland-session.target`.

The migration deletes active end4 source/config trees, including local `config/quickshell`, matugen/fuzzel support, and imported end4 Hyprland layering. Hyprland remains repository-owned through a small checked-in base plus generated host facts, app defaults, rules, startup, and Caelestia global-shortcut or CLI-backed keybinds.

Static validation passed for upstream package availability, generated service/config/package shape, absence of active end4 references, diff hygiene, and the Axiom NixOS toplevel build. Live graphical shell behavior still needs an Axiom Hyprland session because the automation shell had no Wayland/Hyprland environment.

## Reusable Decisions

- Use `caelestia-shell.packages.<system>.with-cli` for Axiom so the shell and CLI stay aligned with upstream Nix packaging.
- Keep a local NixOS integration boundary for Caelestia service ownership, XDG config generation, reload hooks, and session target wiring instead of importing the upstream Home Manager module as primary architecture.
- Keep generated Caelestia config minimal and only encode repository-owned host policy such as default apps and dangerous launcher-action disablement.
- Do not preserve end4 as a fallback product path. Historical Legion evidence can remain, but current desktop truth must point to Caelestia.
- Keep Darwin isolated from Linux-only Caelestia, Hyprland, UWSM, and desktop service concerns.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-caelestia-shell-migration/plan.md`
- `log`: `.legion/tasks/axiom-caelestia-shell-migration/log.md`
- `tasks`: `.legion/tasks/axiom-caelestia-shell-migration/tasks.md`
- `rfc`: `.legion/tasks/axiom-caelestia-shell-migration/docs/rfc.md`
- `rfc-review`: `.legion/tasks/axiom-caelestia-shell-migration/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-caelestia-shell-migration/docs/test-report.md`
- `review`: `.legion/tasks/axiom-caelestia-shell-migration/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-caelestia-shell-migration/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-caelestia-shell-migration/docs/pr-body.md`

## Notes

- Post-deployment validation should restart `caelestia-shell.service` in the live Hyprland session and exercise launcher/sidebar/session, tray/notifications, OSD/media/brightness, screenshot/recording, wallpaper, lock/polkit, and default app paths.
