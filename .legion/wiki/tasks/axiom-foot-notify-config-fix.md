# Axiom Foot Notify Config Fix

## Metadata

- `task-id`: `axiom-foot-notify-config-fix`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This hotfix removes an unsupported `[main].notify` option from Axiom's global Foot config. The live failure path was `/home/c1/.config/foot/foot.global.ini`, and `modules/desktop/term/foot.nix` links that file from repository source `config/foot/foot.ini`.

The failure was reproduced with `foot --check-config --config config/foot/foot.ini` under Foot 1.25.0. After removing the invalid key, both the repository config and the Nix-evaluated `foot/foot.global.ini` source path validate, `git diff --check` passes, and the full Axiom NixOS toplevel build passes.

## Reusable Decisions

- Foot config changes should be validated with `foot --check-config --config <path>` against both the edited repository file and the Nix-evaluated Home Manager source path when the live error comes from `~/.config/foot`.
- Unsupported terminal config keys should be removed rather than preserved behind fallback logic unless a current package-supported replacement is identified.
- Terminal notification behavior should not be restored by guessing old Foot option names; use a supported option or a separate wrapper design.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-foot-notify-config-fix/plan.md`
- `log`: `.legion/tasks/axiom-foot-notify-config-fix/log.md`
- `tasks`: `.legion/tasks/axiom-foot-notify-config-fix/tasks.md`
- `test-report`: `.legion/tasks/axiom-foot-notify-config-fix/docs/test-report.md`
- `review`: `.legion/tasks/axiom-foot-notify-config-fix/docs/review-change.md`
- `walkthrough`: `.legion/tasks/axiom-foot-notify-config-fix/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/axiom-foot-notify-config-fix/docs/pr-body.md`

## Notes

- Live deployment still needs a normal switch/reload before opening Foot from the usual terminal path confirms the runtime abort is gone.
