# Test Report: Axiom Caelestia Wallpaper And Launcher Fix

## Summary

PASS

The Axiom configuration evaluates and builds with the Caelestia runtime integration changes. Targeted evaluation confirms Caelestia owns wallpaper on Axiom, `swaybg` startup is gated off, the shell service uses `--no-duplicate`, service PATH contains launcher/runtime app dependencies, restart keybinds stay in systemd ownership, and ordinary lock paths avoid `loginctl lock-session`.

## Commands

### Targeted Integration Eval

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; lib = flake.lib; keybinds = cfg.home.configFile."hypr/custom/keybinds.conf".text; hypridle = builtins.readFile ./config/hypr/hypridle.conf; service = cfg.systemd.user.services.caelestia-shell; servicePath = map toString service.path; in { wallpaperEnabled = cfg.modules.desktop.caelestia.wallpaper.enable; wallpaperPath = cfg.modules.desktop.caelestia.wallpaper.path; shellJson = builtins.fromJSON cfg.home.configFile."caelestia/shell.json".text; hasSwaybgStartupHook = builtins.hasAttr "10-wallpaper" cfg.hey.hooks.startup; execStart = service.serviceConfig.ExecStart; hasExecStartPre = service.serviceConfig ? ExecStartPre; pathHasApp2unit = lib.any (p: lib.hasInfix "app2unit" p) servicePath; pathHasUtilLinux = lib.any (p: lib.hasInfix "util-linux" p) servicePath; pathHasZen = lib.any (p: lib.hasInfix "zen-beta" p) servicePath; pathHasFoot = lib.any (p: lib.hasInfix "foot" p) servicePath; keybindsUseSystemdRestart = lib.hasInfix "systemctl --user restart caelestia-shell.service" keybinds; keybindsAvoidManualShell = !(lib.hasInfix "$caelestiaShell" keybinds) && !(lib.hasInfix "pkill -x caelestia-shell" keybinds); keybindsUseHyprlock = lib.hasInfix "Super+Shift, L, exec, hyprlock" keybinds; hypridleUsesHyprlockPath = lib.hasInfix "on-timeout = $lock_cmd" hypridle && lib.hasInfix "before_sleep_cmd = $lock_cmd" hypridle; hypridleAvoidsLoginctlLock = !(lib.hasInfix "loginctl lock-session" hypridle); }'
```

Result: PASS

Evidence:

```json
{"execStart":"/nix/store/ixy6k447sc1xmvp030jyrkz3qzrmjfva-caelestia-shell-1.0.0/bin/caelestia-shell --no-duplicate","hasExecStartPre":true,"hasSwaybgStartupHook":false,"hypridleAvoidsLoginctlLock":true,"hypridleUsesHyprlockPath":true,"keybindsAvoidManualShell":true,"keybindsUseHyprlock":true,"keybindsUseSystemdRestart":true,"pathHasApp2unit":true,"pathHasFoot":true,"pathHasUtilLinux":true,"pathHasZen":true,"shellJson":{"background":{"wallpaperEnabled":true},"general":{"apps":{"audio":["pavucontrol"],"explorer":["thunar"],"playback":["mpv"],"terminal":["foot"]}},"launcher":{"enableDangerousActions":false}},"wallpaperEnabled":true,"wallpaperPath":"/home/c1/the-great-sage.jpg"}
```

Why this command: it directly checks the generated Nix values that correspond to each acceptance criterion without requiring a live Wayland session.

### Axiom Toplevel Build

Command:

```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure
```

Result: PASS

Notes:

- The build completed successfully.
- Existing warnings were emitted for `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; these are pre-existing repository warnings and not caused by this task's changes.

Why this command: the toplevel build proves the full Axiom system configuration, generated user units, home-manager files, and changed Nix modules compose successfully.

## Skipped

- Live Wayland validation was not performed in this verification stage. It must happen after deployment in the real Hyprland session: confirm only one Caelestia quickshell instance, one Caelestia background owner, no `swaybg`, and launcher Enter starts Zen.

## Non-Validation Corrections

- Two initial `nix eval` attempts using direct attr paths for `home.configFile` entries with slashes failed because slash-containing attribute names require quoted Nix expressions. They were corrected with `builtins.getFlake` expressions and are not implementation failures.
