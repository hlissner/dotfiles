# Test Report

## Summary

- Result: PASS
- Date: 2026-05-11
- Scope: Axiom Fcitx5 theme accent alignment with the active shell/desktop pink accent.

## Commands And Evidence

1. `nix eval --impure --json '.#nixosConfigurations.axiom.config' --apply '<fcitx5 generated config assertions>'`
   - Result: PASS.
   - Output showed `theme = "catppuccin-mocha-pink"`, `userFile = "Theme=catppuccin-mocha-pink\n"`, and `force = true`.
   - Output preserved addons: `fcitx5-gtk`, `fcitx5-qt6`, `fcitx5-rime`, `fcitx5-chinese-addons`, and `catppuccin-fcitx5`.

2. `nix eval --impure --json '.#nixosConfigurations.axiom.config.modules.desktop.input.fcitx5' --apply '<axiom input option assertions>'`
   - Result: PASS.
   - Output showed `enable = true`, `flavor = "mocha"`, `accent = "pink"`, `rime = true`, and `pinyin = true`.

3. Assembled generated Hyprland config under a task-local temporary directory and ran the configured Hyprland package with a task-local `XDG_RUNTIME_DIR`:
   - `XDG_RUNTIME_DIR="$runtime_dir" $(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath')/bin/Hyprland --config "$tmpdir/hyprland.conf" --verify-config`
   - Result: PASS, `config ok`.
   - The first attempt without `XDG_RUNTIME_DIR` failed before config parsing with `XDG_RUNTIME_DIR is not set`; the rerun used a task-local runtime directory and validated the parser successfully.

4. `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
   - Result: PASS.
   - This builds the Axiom system closure including regenerated Fcitx5 system and Home Manager classic UI config.

5. `git diff --check`
   - Result: PASS with no output.

## Why These Checks

- The focused Fcitx5 evals directly prove the requested theme value and that Rime/Pinyin/addons remain enabled.
- Hyprland parser validation checks that the broader generated desktop config still parses after rebuilding from the branch.
- The Axiom toplevel build is the strongest static integration check available without deploying the host.

## Non-Blocking Warnings

- Nix repeatedly warns that `specialArgs.pkgs` causes `nixpkgs.config` and `nixpkgs.overlays` to be ignored. This predates this task.
- Build output includes existing warnings for deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` usage. These are unrelated.
- Hyprland `--verify-config` warns that it is launched without `start-hyprland`; this is expected for parser validation.

## Skipped

- Live visual confirmation of the Fcitx5 candidate UI colors. This requires deploying/switching Axiom and restarting Fcitx5 or the user session.
