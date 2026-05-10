## Summary

- Generate a decode-safe Caelestia wallpaper derivative for Axiom instead of feeding Qt the oversized source image directly.
- Set `QT_QPA_PLATFORMTHEME=qt6ct` across the Caelestia service and generated Hyprland/UWSM session env, following upstream Caelestia issue #1282.
- Preserve Caelestia wallpaper ownership and avoid overwriting manually selected wallpapers.

## Validation

- `nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; userName = cfg.user.name; in { hyprEnv = cfg.home.file.".config/hypr/custom/env.conf".text; uwsmEnv = cfg.home.file.".config/uwsm/env".text; serviceEnv = cfg.systemd.user.services.caelestia-shell.environment; startupHook = cfg.hey.hooks.startup."05-session"; execStartPre = cfg.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre; qt6ctInUserPackages = builtins.any (p: (p.pname or "") == "qt6ct") cfg.users.users.${userName}.packages; }'`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure`
- ImageMagick smoke test converted `/home/c1/the-great-sage.jpg` to `3840x1858 757392B` using the service-script transform.

## Live Follow-Up

- Restart Hyprland after deployment so the `qt6ct` environment reaches newly started processes.
- Confirm Caelestia uses `/home/c1/.local/state/caelestia/wallpaper/generated.jpg`, no `swaybg` process is active, one Caelestia quickshell instance is active, and launcher icons no longer render as color blocks.
