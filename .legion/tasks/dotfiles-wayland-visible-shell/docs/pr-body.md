## Summary

- Fixes `axiom` reaching a live Hyprland cursor with a black desktop by replacing the foreground startup `hyprlock --immediate` pseudo-login hook.
- Adds a minimal `05-session` startup hook that imports compositor environment variables and starts `hyprland-session.target` before visual shell/wallpaper hooks run.
- Keeps DMS/Quickshell and wallpaper attached to the existing session-target path instead of adding scattered startup commands.

## Verification

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- `Hyprland --verify-config` against combined generated/base/theme config
- Targeted eval confirmed `05-session` starts `hyprland-session.target`, no startup hook launches `hyprlock --immediate`, DMS remains wanted by session targets, and wallpaper starts through `swaybg`.
- `git diff --check`

## Review/Risk

- Review result: PASS, no blocking findings.
- Physical `axiom` visual verification was not run from this environment.
- Startup `hyprlock --immediate` removal is an accepted tradeoff to unblock shell/wallpaper startup; boot-time physical access protection can be handled later with a real greeter or non-blocking lock flow.

## Legion Evidence

- Task: `.legion/tasks/dotfiles-wayland-visible-shell/`
- Test report: `.legion/tasks/dotfiles-wayland-visible-shell/docs/test-report.md`
- Review: `.legion/tasks/dotfiles-wayland-visible-shell/docs/review-change.md`
- Walkthrough: `.legion/tasks/dotfiles-wayland-visible-shell/docs/report-walkthrough.md`
