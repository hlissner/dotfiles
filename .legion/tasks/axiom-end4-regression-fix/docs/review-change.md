# Review Change: Axiom End4 Regression Fix

> Date: 2026-05-09
> Task: `axiom-end4-regression-fix`
> Worktree: `/home/c1/dotfiles/.worktrees/axiom-end4-regression-fix`

## Decision

PASS.

No blocking correctness, scope, maintainability, or security findings were found for the requested regression fix. The change remains within the task contract: it keeps imported end4 `ii` as the active shell, fixes the observed missing Kirigami QML module path, restores Axiom-owned Hyprland keyboard facts and host hotkeys, and records credible repository-local verification with clear live-session follow-up.

## Blocking Findings

None.

## Review Evidence

- End4 import goal preserved: `modules/desktop/quickshell.nix` still runs `quickshell --config ii` through `systemd.user.services.quickshell.serviceConfig.ExecStart`; there is no rollback to legacy `axiom-shell` or substrate-only path.
- Kirigami failure addressed directly: the wrapper QML path now includes `kdePackages.kirigami.unwrapped` and exports both `QML2_IMPORT_PATH` and `QML_IMPORT_PATH`, matching the logged failure for `import org.kde.kirigami` in end4 Waffle QML.
- Hyprland XKB facts restored after upstream defaults: `config/hypr/hyprland.conf` sources `hyprland/general.conf` before `custom/general.conf`, and the generated custom file now emits `kb_layout`, `kb_variant`, and `kb_options` from Nix-owned host facts. The test report confirms Axiom evaluates to `us` / `colemak` / `terminate:ctrl_alt_bksp`.
- Hotkeys are real end4 entrypoints: `Super+Space` calls `qs -c $qsConfig ipc call search toggle`, and end4 defines a `search` IPC handler; `Super+A` calls `qs -c $qsConfig ipc call sidebarLeft toggle`, and end4 defines `sidebarLeft.toggle` handlers.
- Verification is sufficient for PR readiness despite no live switch from this worktree: the evidence includes the original live failure, generated config evals, package build, QML module path existence check, service `ExecStart` eval, a headless quickshell smoke that progresses past the prior Kirigami failure to the expected compositor backend limit, and full Axiom toplevel build. The missing live restart is documented as a post-deployment validation step rather than a blocker for this repository-local review.

## Non-Blocking Residual Risks

- Live behavior still needs confirmation after the fixed generation is switched or the service is restarted: `quickshell.service` logs should be checked for absence of `org.kde.kirigami` failures, and `Super+Space`, `Super+A`, and Colemak behavior should be tested in the actual Hyprland session.
- `Super+Space` retains a `fuzzel` fallback if the end4 IPC call fails. This does not hide the primary fix in the submitted evidence because the task also validates `ii` loadability and service wiring, but future runtime regressions could still appear to have a degraded launcher path until logs are inspected.

## Security Lens

Security triggers were not materially present: the change affects local runtime import paths, generated Hyprland keybind commands, and local Quickshell IPC calls, with no auth, secrets, protocol boundary, or remote/user-controlled privileged input changes. A limited trust review found no new secret exposure or privilege escalation path.
