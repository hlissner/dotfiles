# Report Walkthrough

Mode: implementation

## Reviewer Summary

This implementation fixes the `axiom` Wayland session reaching a live Hyprland compositor with a visible cursor but an otherwise black desktop. The change is intentionally minimal: it replaces the startup lock-screen gate with a session bootstrap hook that connects the compositor session to `hyprland-session.target`, allowing DMS/Quickshell and wallpaper startup to proceed.

## User-Visible Bug

After prior runtime fixes, networking worked and Hyprland started far enough to show a cursor, but the desktop surface remained black. That meant the compositor was alive while the intended product layer - DMS/Quickshell shell, wallpaper/background, and user-session services - was not visibly attached or was blocked during startup.

## Root Cause

The generated Hyprland startup path ran:

- `exec-once = hey hook startup`
- startup hook `05-loginscreen`
- foreground `hyprlock --immediate`

That lock-screen pseudo-login hook ran before `hyprland-session.target` was started and before the later wallpaper hook. Existing evidence showed this could leave Hyprland alive while masking or blocking the shell/background startup path.

DMS itself was already enabled and wanted by `hyprland-session.target` and `graphical-session.target`; the missing piece was getting the session target started predictably before visual shell and wallpaper hooks.

## Minimal Fix

Changed `modules/desktop/hyprland.nix` only:

- Replaced `startup."05-loginscreen"` with `startup."05-session"`.
- Kept compositor environment import through `systemctl --user import-environment`.
- Removed foreground `hyprlock --immediate` from startup.
- Started `hyprland-session.target` before the wallpaper hook.
- Left manual lock behavior available through existing Hyprland keybindings.

This keeps the fix centralized in the Hyprland session bootstrap instead of spreading ad-hoc shell startup commands through unrelated modules.

## Files To Review

- `modules/desktop/hyprland.nix`: session startup hook changed from lock-screen pseudo-login to user-session bootstrap.
- `.legion/tasks/dotfiles-wayland-visible-shell/docs/test-report.md`: build, Hyprland parser, targeted eval, regression search, and diff hygiene evidence.
- `.legion/tasks/dotfiles-wayland-visible-shell/docs/review-change.md`: readiness review and risk/security assessment.

## Verification Evidence

Result: PASS.

Evidence from `docs/test-report.md`:

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- Combined generated/base/theme Hyprland config parser validation passed with `config ok`.
- Targeted eval confirmed `exec-once = hey hook startup` remains active.
- Targeted eval confirmed startup hooks are `05-session` and `10-wallpaper`.
- Targeted eval confirmed `05-session` starts `hyprland-session.target`.
- Targeted eval confirmed no startup hook launches `hyprlock --immediate`.
- Targeted eval confirmed DMS remains wanted by `hyprland-session.target` and `graphical-session.target`.
- Targeted eval confirmed wallpaper still starts through `swaybg`.
- Targeted eval confirmed Quickshell remains enabled.
- Regression search found no active `hyprlock --immediate` startup hook.
- `git diff --check` passed.

## Review Result

`docs/review-change.md` result: PASS.

The review found:

- No blocking findings.
- Scope is limited to the Hyprland session bootstrap.
- Verification is adequate for delivery.
- Security lens was applied because lock-screen/session startup behavior changed.
- No concrete privilege escalation, remote exposure, secret handling issue, or new trust-boundary crossing was found.

## Residual Risks

- Physical visual verification on the actual `axiom` display was not run from this environment.
- Local validation proves generated startup wiring, system build behavior, and Hyprland config parsing, but not live DMS/Quickshell rendering on the physical display.
- Removing startup `hyprlock --immediate` weakens the previous boot-time physical-access gate.

## Rollback / Follow-Up Notes

Rollback would restore the prior startup lock-screen gate, but that would also restore the risk of masking or blocking shell/wallpaper startup.

Follow-up, if boot-time physical access protection is still required:

- Add a real authenticated greeter or a non-blocking lock flow.
- Do not gate shell/background startup behind foreground `hyprlock --immediate`.
- Validate the final behavior on physical `axiom` hardware.
