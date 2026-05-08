# Review Change

## Summary

Result: PASS

The visible-shell startup fix is ready for walkthrough and PR delivery. The change stays within scope, verification evidence is adequate, and no blocking correctness, maintainability, or security findings were found.

## Blocking Findings

None.

## Scope Review

The implementation is limited to `modules/desktop/hyprland.nix`, replacing the foreground startup pseudo-login hook with a session bootstrap hook:

- `startup."05-loginscreen"` was replaced by `startup."05-session"`.
- The new hook imports compositor environment variables and starts `hyprland-session.target`.
- Startup no longer runs foreground `hyprlock --immediate` before shell and wallpaper hooks.

This matches the task scope: Hyprland session bootstrap, DMS/Quickshell user-session attachment, and wallpaper/background visibility.

## Verification Review

Verification is adequate for delivery:

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- Combined generated/base/theme Hyprland config parser validation passed with `config ok`.
- Targeted eval confirms `exec-once = hey hook startup` remains active, startup hooks are `05-session` and `10-wallpaper`, `05-session` starts `hyprland-session.target`, no startup hook launches `hyprlock --immediate`, DMS remains wanted by session targets, and wallpaper still starts through `swaybg`.
- `git diff --check` passed.

Physical visual verification on `axiom` was not run from this environment. That residual risk is documented in `docs/test-report.md`.

## Security Lens

Security lens applied because the change alters lock-screen/session startup behavior.

The previous foreground `hyprlock --immediate` pseudo-login path is removed from startup. This weakens the old boot-time physical-access gate, but it directly satisfies the task acceptance criterion that the session must no longer depend on an immediate lock-screen path that can mask or block the shell. Manual lock behavior remains available through the existing Hyprland keybinding path.

No concrete privilege escalation, remote exposure, secret handling issue, or new trust-boundary crossing was found.

## Non-Blocking Suggestions

- If boot-time physical access protection is still required, handle it as a separate follow-up with a real authenticated greeter or non-blocking lock flow that does not gate shell/wallpaper startup.

## Residual Risks

- Live DMS/Quickshell rendering on the physical `axiom` display remains unproven without machine-local validation.
- A future authenticated greeter decision may be needed to replace the removed pseudo-login behavior.

## Decision

PASS. Proceed to walkthrough, wiki writeback, PR delivery, and lifecycle cleanup.
