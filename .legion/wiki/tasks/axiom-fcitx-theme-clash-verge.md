# Axiom Fcitx Theme And Clash Verge

## Metadata

- `task-id`: `axiom-fcitx-theme-clash-verge`
- `status`: `active, PR lifecycle pending`
- `risk`: `low`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes the `axiom` Fcitx5 Catppuccin visibility gap by managing the effective user-level `fcitx5/conf/classicui.conf` theme selection in addition to the existing system-level Fcitx5 setting.

It adds a reusable `modules.desktop.apps.clash-verge` module using `pkgs.clash-verge-rev` and enables it only on `axiom`.

Clash Verge profile, subscription, credential, routing, and daemon management remain out of scope and user-managed.

## Reusable Decisions

- Fcitx5 Catppuccin theme selection should be validated at both `environment.etc."xdg/fcitx5/conf/classicui.conf"` and `home.configFile."fcitx5/conf/classicui.conf"` when runtime symptoms suggest stale user config can override system defaults.
- Force-managing `fcitx5/conf/classicui.conf` is acceptable for the theme fix because it only replaces the Fcitx classic UI settings file and does not touch Rime schemas, dictionaries, or private input data paths.
- Clash Verge belongs under reusable desktop app modules as an installed GUI package; proxy profiles/subscriptions/routing are not implied by installing the app.

## Validation

Focused Nix evals passed for user-level and system-level Fcitx classic UI theme config, the user-level force flag, Clash Verge package availability, Clash Verge enablement on `axiom`, final `users.users.c1.packages` inclusion, and the `axiom` system toplevel derivation.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-fcitx-theme-clash-verge/plan.md`
- `log`: `.legion/tasks/axiom-fcitx-theme-clash-verge/log.md`
- `tasks`: `.legion/tasks/axiom-fcitx-theme-clash-verge/tasks.md`
- `test-report`: `.legion/tasks/axiom-fcitx-theme-clash-verge/docs/test-report.md`
- `review`: `.legion/tasks/axiom-fcitx-theme-clash-verge/docs/review-change.md`
- `report`: `.legion/tasks/axiom-fcitx-theme-clash-verge/docs/report-walkthrough.md`
