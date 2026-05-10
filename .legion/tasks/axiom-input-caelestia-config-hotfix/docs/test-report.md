# Test Report

## Summary

- Result: PASS
- Date: 2026-05-10
- Scope: Axiom generated Hyprland keybind/input config and mutable Caelestia `shell.json` seed behavior.

## Commands And Evidence

1. `nix eval --impure --json '.#nixosConfigurations.axiom.config' --apply '<generated-config assertions>'`
   - Result: PASS.
   - Output returned all true for `hasUpperSuper`, `hasNoMixedSuper`, `hasUpperCtrlAlt`, `hasColemak`, `hasLayout`, `noManagedShellJson`, `hasShellSeedPreStart`, and `hasWallpaperPreStart`.
   - This proves generated keybinds use canonical uppercase modifiers, Axiom still emits `kb_layout = us` and `kb_variant = colemak`, Home Manager no longer owns `caelestia/shell.json`, and the Caelestia service has both shell-config and wallpaper pre-start hooks.

2. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre' --apply 'pre: builtins.elemAt pre 0'`
   - Result: PASS.
   - Output after the final implementation: `/nix/store/00fr1dm7xb5nbp3i4mdh2frblhy92cb0-caelestia-seed-shell-config`.
   - Inspected the realized script and seed JSON. The script writes `/home/c1/.config/caelestia/shell.json` only when the path is missing or when the existing symlink resolves under `/nix/store`, and uses `mv -f` to replace the previous immutable Nix-store symlink with a real file. The seed JSON includes `"utilities":{"toasts":{"kbLayoutChanged":false}}`.

3. Assembled generated Hyprland config under a task-local temporary directory and ran the configured Hyprland package:
   - `$(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath')/bin/Hyprland --config "$tmpdir/hyprland.conf" --verify-config`
   - Result: PASS, `config ok`.
   - This proves the canonical modifier spelling and generated config remain accepted by the evaluated Hyprland package.

4. `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
   - Result: PASS.
   - This builds the Axiom system closure including regenerated Home Manager files and the updated Caelestia user service unit.

5. `git diff --check`
   - Result: PASS with no output.
   - This checks the patch for whitespace errors before review.

## Why These Checks

- Focused Nix eval assertions directly prove the generated text and service ownership claims in the acceptance criteria.
- Inspecting the realized seed script proves the mutable-file guard that protects real user edits from being overwritten.
- Hyprland `--verify-config` catches parser regressions that Nix evaluation cannot catch.
- The Axiom toplevel build is the strongest static integration check available without deploying and restarting the live graphical session.

## Non-Blocking Warnings

- Nix repeatedly warns that `specialArgs.pkgs` causes `nixpkgs.config` and `nixpkgs.overlays` to be ignored. This predates the task.
- Build output includes existing warnings for deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` usage. These are unrelated to this hotfix.
- Hyprland `--verify-config` warns that it is launched without `start-hyprland`; this is expected for parser validation and not a session startup change.
- One intermediate Nix regex assertion command was discarded because the regex was invalid; it was replaced by the seed script/JSON inspection and does not indicate an implementation failure.

## Skipped

- Live physical Super-key smoke and live Caelestia boot toast confirmation. `hyprctl -j devices` could not run in this automation context because `HYPRLAND_INSTANCE_SIGNATURE` is not set, so post-deploy validation in the real Axiom Hyprland session is still required.
