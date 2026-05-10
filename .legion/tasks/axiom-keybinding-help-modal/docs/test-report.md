# Test Report

## Summary

- Result: PASS
- Date: 2026-05-11
- Scope: Axiom generated Hyprland `SUPER+/` keybinding help modal.

## Commands And Evidence

1. `nix eval --impure --json '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text' --apply '<keybind assertions>'`
   - Result: PASS.
   - Output returned `hasHelpBind = true`, `hasLauncherBind = true`, and `hasReloadBind = true`.
   - This proves the generated keybind file includes `bind = SUPER, slash, exec, <axiom-keybinding-help>` and preserves existing launcher/reload bindings.

2. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text' --apply '<extract help script path>'`
   - Result: PASS.
   - Output: `/nix/store/65lpd0xy0s534j8d6zx8di3cbvxcsx89-axiom-keybinding-help`.

3. `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
   - Result: PASS.
   - This built the Axiom closure, including the generated keybinding help text file, the generated `axiom-keybinding-help` script, regenerated Hyprland keybind config, and updated Home Manager generation.

4. Inspected realized script and help text after the build.
   - Script calls `zenity --text-info --modal --title "Axiom keyboard shortcuts" --width 760 --height 720 --filename <axiom-keybindings.txt>`.
   - Help text lists `SUPER+/` plus the current shell, service, app/window, capture, workspace, media/brightness, and reload shortcuts.

5. Assembled generated Hyprland config under a task-local temporary directory and ran the configured Hyprland package with a task-local `XDG_RUNTIME_DIR`:
   - `XDG_RUNTIME_DIR="$runtime_dir" $(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath')/bin/Hyprland --config "$tmpdir/hyprland.conf" --verify-config`
   - Result: PASS, `config ok`.

6. `git diff --check`
   - Result: PASS with no output.

## Why These Checks

- Focused Nix evals directly prove the generated keybind shape.
- The Axiom toplevel build proves the generated helper script and text file are part of the evaluated system closure.
- Inspecting the realized script/text proves the modal command and user-facing content.
- Hyprland parser validation catches generated keybind syntax errors that Nix eval alone cannot catch.

## Non-Blocking Warnings

- Nix repeatedly warns that `specialArgs.pkgs` causes `nixpkgs.config` and `nixpkgs.overlays` to be ignored. This predates this task.
- Build output includes existing warnings for deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` usage. These are unrelated.
- Hyprland `--verify-config` warns that it is launched without `start-hyprland`; this is expected for parser validation.

## Skipped

- Live confirmation that pressing the physical `SUPER+/` key opens the modal. This requires deploying/switching Axiom and running inside the real Hyprland session.
