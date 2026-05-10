# Test Report

## Summary

- Result: PASS
- Date: 2026-05-10
- Scope: Axiom Caelestia README-alignment NixOS configuration changes.

## Commands

1. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.home.configFile."caelestia/shell.json".text'`
   - Verified Caelestia shell JSON contains `appearance.font.family` with `clock = Rubik`, `material = Material Symbols Rounded`, `mono = CaskaydiaCove NF`, `sans = Rubik`.
   - Verified `general.apps.explorer = ["thunar"]` and terminal remains `foot`.

2. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.home.configFile."foot/foot.local.ini".text'`
   - Verified Foot generates `font=FiraCode Nerd Font Mono:size=9.500000`.

3. `nix eval --impure --json '.#nixosConfigurations.axiom.config.fonts.fontconfig.defaultFonts'`
   - Verified `sansSerif = ["Rubik", "LXGW Neo Xihei", "Noto Sans CJK SC"]`.
   - Verified `monospace = ["CaskaydiaCove NF", "Sarasa Mono SC", "Noto Sans CJK SC"]`.

4. `nix eval --impure --json '.#nixosConfigurations.axiom.config.modules.theme.fonts' --apply 'fonts: { sans = fonts.sans.name; mono = fonts.mono.name; terminal = fonts.terminal.name; }'`
   - Verified theme font names are `Rubik`, `CaskaydiaCove NF`, and `FiraCode Nerd Font Mono`.

5. `nix eval --impure --json '.#nixosConfigurations.axiom.config.environment.sessionVariables' --apply 'env: { QT_QPA_PLATFORM = env.QT_QPA_PLATFORM; QT_QPA_PLATFORMTHEME = env.QT_QPA_PLATFORMTHEME; QT_WAYLAND_DISABLE_WINDOWDECORATION = env.QT_WAYLAND_DISABLE_WINDOWDECORATION; QT_AUTO_SCREEN_SCALE_FACTOR = env.QT_AUTO_SCREEN_SCALE_FACTOR; }'`
   - Verified repo-owned session env exports `QT_QPA_PLATFORM = wayland;xcb`, `QT_QPA_PLATFORMTHEME = qtengine`, `QT_WAYLAND_DISABLE_WINDOWDECORATION = 1`, and `QT_AUTO_SCREEN_SCALE_FACTOR = 1`.

6. `nix eval --impure --json '.#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.environment' --apply 'env: { QT_QPA_PLATFORM = env.QT_QPA_PLATFORM; QT_QPA_PLATFORMTHEME = env.QT_QPA_PLATFORMTHEME; QT_WAYLAND_DISABLE_WINDOWDECORATION = env.QT_WAYLAND_DISABLE_WINDOWDECORATION; QT_AUTO_SCREEN_SCALE_FACTOR = env.QT_AUTO_SCREEN_SCALE_FACTOR; }'`
   - Verified the Caelestia shell service has the same Qt environment.

7. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/env.conf".text'`
   - Verified generated Hyprland env includes `QT_QPA_PLATFORMTHEME,qtengine` and Qt Wayland decoration variables.

8. `nix eval --impure --raw '.#nixosConfigurations.axiom.config.home.configFile."uwsm/env".text'`
   - Verified generated UWSM env includes `export QT_QPA_PLATFORMTHEME=qtengine` and Qt Wayland decoration variables.

9. `nix eval --impure --json '.#nixosConfigurations.axiom.config.programs.qtengine.enable'`
   - Verified `programs.qtengine.enable = true`.

10. `nix eval --impure --json '.#nixosConfigurations.axiom.config.services.gvfs.enable'`
    - Verified GVFS is enabled for Thunar.

11. `nix eval --impure --json '.#nixosConfigurations.axiom.config.programs.thunar.enable'`
    - Verified Thunar is enabled.

12. Generated a temporary Hyprland fixture from the evaluated `hypr/*.conf` and `hypr/custom/*.conf` files, then ran the configured Hyprland package:
    - `$(nix eval --impure --raw '.#nixosConfigurations.axiom.config.programs.hyprland.package.outPath')/bin/Hyprland --config "$tmpdir/hyprland.conf" --verify-config`
    - Result: `config ok` with Hyprland `0.53.3`.

13. `nix build '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
    - Result: PASS with no output.

## Why These Checks

- Focused `nix eval` checks directly prove the generated settings requested in the acceptance criteria.
- The generated Hyprland fixture checks syntax against the exact configured Hyprland package instead of an incidental `nixpkgs#hyprland` version.
- The toplevel build is the strongest static integration check available without deploying and restarting the live graphical session.

## Non-Blocking Warnings

- Nix repeatedly warns that `specialArgs.pkgs` causes `nixpkgs.config` and `nixpkgs.overlays` to be ignored. This warning predates this task and is not specific to the Caelestia alignment.
- Some evals warn that `mesa.drivers` is deprecated and that `system` has been renamed to `stdenv.hostPlatform.system`. These are unrelated existing warnings.

## Skipped

- Live visual validation of rounded windows, rendered font fallback, and toolkit theme appearance. These require deploying the system and restarting Hyprland/app processes.
