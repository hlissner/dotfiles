# Review Change: axiom-desktop-polish-followup

## Verdict

PASS

## Blocking Findings

None.

## Scope Review

- Production changes are limited to the approved surfaces: `modules/desktop/hyprland.nix`, `modules/desktop/apps/steam.nix`, and `hosts/axiom/default.nix`.
- Legion evidence changes are task-local under `.legion/tasks/axiom-desktop-polish-followup/`.
- The change does not debug Steam games/Proton, package opencode, restore end4/legacy Quickshell, or change Darwin host behavior.

## Correctness Review

- Steam receives `STEAM_FORCE_DESKTOPUI_SCALING` through the actual wrapped `bin/steam`, preserving existing fake-home and library-fix behavior.
- Hyprland emits `xwayland.force_zero_scaling = true` only for scaled monitor configs, matching the RFC review suggestion and limiting unscaled-host surprise.
- Caelestia keybinds now route through supported `caelestia shell` IPC commands for drawers, brightness, media, and picker actions, avoiding the reported broken `global, caelestia:*` path.
- Axiom no longer relies on a literal `environment.variables.PATH`; opencode is present in generated zsh startup and UWSM desktop session PATH.
- Verification evidence is credible for local readiness: targeted eval, Steam wrapper readback, package closure check, Hyprland parser, diff hygiene, and Axiom build all passed.

## Security Lens

Security lens applied because the change touches session environment/PATH and user-session command dispatch.

- No privileged system service PATH is changed. The opencode directory is added to user zsh and the Hyprland/UWSM user session path.
- The desktop session already places a user-writable bin directory first (`${config.home.binDir}`); adding `$HOME/.opencode/bin` does not introduce a new privilege boundary.
- Caelestia keybinds execute fixed, repository-generated commands, not user-controlled input.
- No secrets, credentials, auth policy, network exposure, signing, or cross-user data boundary is changed.

No exploitable trust-boundary issue found.

## Residual Risks

- Live Steam crispness, Caelestia shortcut behavior, and `command -v opencode` still need Axiom post-deploy smoke checks.
- Removing Super-key tap-to-launch semantics may be noticeable if the user depended on tapping Super rather than `Super+Space`; the RFC explicitly leaves this as a follow-up if needed.

## Decision

Ready for walkthrough, wiki closeout, and PR lifecycle.
