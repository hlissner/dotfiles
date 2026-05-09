# Review Change: Axiom Foot Notify Config Fix

> Date: 2026-05-09
> Task: `axiom-foot-notify-config-fix`
> Worktree: `/home/c1/dotfiles/.worktrees/axiom-foot-notify-config-fix`

## Decision

PASS.

No blocking correctness, scope, maintainability, or security findings were found for the requested Foot startup fix. The change is the smallest compatible repair: remove the unsupported `[main].notify` key from the repository config that Home Manager links as `foot.global.ini`.

## Blocking Findings

None.

## Review Evidence

- Scope compliance: the only product config change is `config/foot/foot.ini`, and it removes only the startup-blocking `notify` option.
- Source-to-live path confirmed: `modules/desktop/term/foot.nix` links `config/foot/foot.ini` as `foot/foot.global.ini`, matching the user's reported failing path.
- Correctness evidence: `foot --check-config --config config/foot/foot.ini` reproduced the original failure before the patch and passes after the patch under Foot 1.25.0.
- Generated-source evidence: evaluating `nixosConfigurations.axiom.config.home.configFile."foot/foot.global.ini".source` and validating that path with Foot also passes.
- Integration evidence: `git diff --check` and the full Axiom NixOS toplevel build pass.

## Non-Blocking Residual Risks

- The removed `notify` setting likely disabled intended terminal notification behavior from an older or different Foot version. That behavior should only be restored later if there is a supported Foot 1.25 option or external wrapper design.
- The fixed generation still needs live deployment; after switch/reload, opening Foot from the normal launcher/keybind path should confirm the runtime error is gone.

## Security Lens

Security triggers were not materially present. The change removes a local notification command from terminal configuration and does not introduce auth, secrets, remote input, privileged execution, or data exposure changes.
