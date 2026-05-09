## Summary

- Remove the unsupported `[main].notify` key from the global Foot config that Home Manager links as `foot.global.ini`.
- Keep the fix scoped to Foot startup compatibility; no terminal default, launcher, shell, Hyprland, or notification-stack redesign.

## Verification

- PASS: reproduced the pre-fix failure with `foot --check-config --config config/foot/foot.ini`.
- PASS: `foot --check-config --config config/foot/foot.ini` after removing the invalid key.
- PASS: Nix-evaluated `foot/foot.global.ini` source path validates with Foot.
- PASS: `git diff --check`.
- PASS: `env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`.

## Risks/Follow-ups

- After deployment, open Foot through the normal launcher/keybind path and confirm it no longer aborts on `foot.global.ini`.
- If terminal notification behavior is still wanted, restore it later through an option supported by the installed Foot version or through an external wrapper design.

## Legion Evidence

- Contract: `.legion/tasks/axiom-foot-notify-config-fix/plan.md`
- Test report: `.legion/tasks/axiom-foot-notify-config-fix/docs/test-report.md`
- Change review: `.legion/tasks/axiom-foot-notify-config-fix/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-foot-notify-config-fix/docs/report-walkthrough.md`
