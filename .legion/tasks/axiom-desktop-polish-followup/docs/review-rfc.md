# RFC Review: axiom-desktop-polish-followup

## Verdict

PASS

## Findings

No blocking findings.

## Review Notes

- Scope is clear enough for implementation: Steam is limited to fractional-scale XWayland/client UI behavior, Caelestia is limited to generated keybind dispatch, and opencode is limited to exposing an existing user-owned bin directory.
- The RFC compares meaningful alternatives instead of assuming one path: Steam-only scaling vs compositor plus client scaling, global shortcut dispatch vs CLI IPC, and literal PATH vs explicit shell/session PATH ownership.
- Rollback is adequately decomposed by subsystem, so Steam/XWayland, Caelestia keybind routing, and opencode PATH can be reverted independently.
- Verification is strong for local evidence: generated Hyprland text, keybind text, Steam wrapper/env shape, UWSM env, zsh env, parser validation, and Axiom build.
- Residual live risk is explicitly recorded: this environment cannot prove physical Steam crispness, DBus/IPC dispatch behavior, or presence of the mutable opencode binary on Axiom.

## Suggestions

- During implementation, keep `xwayland.force_zero_scaling` conditional on a scaled monitor configuration to avoid surprising unscaled Hyprland hosts.
- Prefer generated text assertions over derivation internals for Steam wrapper validation if the wrapper script path is awkward to inspect directly.

## Gate Decision

The design is implementable, verifiable with the available local surfaces, and rollbackable. Proceed to engineering inside the existing worktree/PR envelope.
