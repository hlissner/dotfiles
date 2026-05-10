## Summary

- Fix Steam HiDPI on Axiom's 4K fractional-scale Hyprland session by enabling scaled-monitor XWayland self-scaling and exporting Steam's desktop UI scale in the wrapper.
- Route Caelestia keybinds through supported `caelestia shell` IPC commands instead of the broken `global, caelestia:*` dispatch path.
- Put `$HOME/.opencode/bin` into Axiom zsh and UWSM/Hyprland session PATH without packaging or relocating opencode.

## Validation

- PASS: targeted Nix eval for generated Hyprland keybind/general config, UWSM env, and zsh env
- PASS: wrapped Steam package build/readback confirmed `STEAM_FORCE_DESKTOPUI_SCALING=1.500000`
- PASS: Steam package closure shape still includes Steam, `steam-run`, `steam-gamescope`, `gamescope`, and `gamemode`
- PASS: assembled `Hyprland --verify-config`
- PASS: `git diff --check`
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Notes

- Live Steam crispness, Caelestia shortcut dispatch, and `command -v opencode` remain post-deploy Axiom smoke checks.
- Full evidence: `.legion/tasks/axiom-desktop-polish-followup/docs/test-report.md`
- Readiness review: `.legion/tasks/axiom-desktop-polish-followup/docs/review-change.md`
