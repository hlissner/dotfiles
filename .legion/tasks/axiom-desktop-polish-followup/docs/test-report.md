# Test Report: axiom-desktop-polish-followup

## Summary

- Result: PASS
- Scope: Axiom desktop polish fixes for Steam HiDPI/XWayland rendering, Caelestia keybind dispatch, and opencode shell/session PATH.
- Environment: headless automation shell in `.worktrees/axiom-desktop-polish-followup/`; no live Wayland/Steam/Caelestia GUI smoke was available.

## Commands

| Check | Command | Result | Evidence |
|---|---|---|---|
| Generated desktop fix shape | `nix eval --impure --json --expr '<Axiom generated keybind/general/uwsm/zsh assertions>'` | PASS | JSON returned all true: `hasZeroScaling`, `hasNoCaelestiaGlobal`, `hasDrawerIpc`, `hasMediaIpc`, `hasBrightnessIpc`, `hasPickerIpc`, `hasOpencodeUwsm`, and `hasOpencodeZsh`. |
| Steam wrapper scale | `nix build --impure --print-out-paths --no-link --expr '<Axiom wrapped Steam package>'`; read generated `bin/steam` | PASS | Built wrapper at `/nix/store/qj8zgz3g0dq0dvmy36r7hsg07yzcin3b--nix-store-dyh0fgrj2lcnkl1rz80bl18ds0wbnqs6-steam-1.0.0.85-wrapped`; wrapper exports `STEAM_FORCE_DESKTOPUI_SCALING=${STEAM_FORCE_DESKTOPUI_SCALING-'1.500000'}` before existing fake-home and libfix commands. |
| Steam package closure shape | `nix eval --impure --json --expr '<Axiom environment.systemPackages names>'` | PASS | Evaluated system packages include the wrapped Steam package, `steam-1.0.0.85`, `steam-run`, `steam-gamescope`, `gamescope`, and `gamemode`; Steam remains enabled and in closure. |
| Hyprland parser | `nix build --impure --print-out-paths --no-link --expr '<assembled Axiom Hyprland config>' && <evaluated Hyprland>/bin/Hyprland --verify-config --config <assembled-config>` | PASS | Hyprland reported `config ok` for the assembled generated config. It emitted the expected non-blocking warning about launching without `start-hyprland`. |
| Diff hygiene | `git diff --check` | PASS | No whitespace errors. |
| Axiom system build | `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` | PASS | Axiom toplevel build completed after rebuilding generated Hyprland keybind/general config, UWSM env, zsh env, Steam wrapper, and affected service units. |

## Why These Checks

- The targeted eval proves the core generated text, where this change is applied, without relying on live GUI state.
- The wrapped Steam package build proves the actual executable wrapper exports the intended Steam HiDPI variable, which is stronger than only inspecting source text.
- Hyprland parser validation directly covers generated keybind and `xwayland` syntax, which Nix evaluation alone cannot parse.
- The Axiom toplevel build proves the complete host configuration still evaluates and builds with the Steam, Hyprland, Caelestia, and shell PATH changes together.

## Skipped / Deferred

- Live Steam crispness is deferred to Axiom deployment because this shell has no physical 4K Wayland session.
- Live Caelestia shortcut dispatch is deferred to Axiom deployment because static validation cannot press keys or confirm IPC effects in a running shell.
- `command -v opencode` is deferred to Axiom deployment because opencode is a mutable user-owned install under `$HOME/.opencode/bin`; validation here proves PATH export, not binary existence.

## Notes

- Nix emitted existing non-blocking warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`.
- The Steam wrapper preserves the user's ability to override `STEAM_FORCE_DESKTOPUI_SCALING` because `--set-default` only applies when the variable is unset.
