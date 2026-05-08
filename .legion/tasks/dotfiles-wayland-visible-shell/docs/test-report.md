# Test Report

## Summary

Result: PASS

`axiom` builds successfully, Hyprland config still parses, and targeted evaluation confirms the startup chain now connects Hyprland to the visible shell/background path instead of blocking on foreground `hyprlock --immediate`.

## Commands

### Axiom Toplevel Build

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Evidence:

- Built `nixos-system-axiom-25.11.20260203.e576e3c` successfully.
- Build regenerated `hey`, startup hook files, home-manager files, user units, and the `axiom` system closure.
- Non-blocking pre-existing warnings remain: `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, future `i18n.inputMethod.enabled`, and renamed `system`.

Why this command was chosen:

- It validates the generated NixOS and home-manager integration for the actual affected host.

### Hyprland Config Parser

Command:

```sh
hypr=$(nix eval --impure --raw .#nixosConfigurations.axiom.config.programs.hyprland.package)
full=$(nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake (toString ./.); c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; base = builtins.replaceStrings [ "source = ~/.config/hypr/hyprland.pre.conf\n" "source = ~/.config/hypr/hyprland.post.conf\n" ] [ "" "" ] (builtins.readFile ./config/hypr/hyprland.conf); in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/hyprland.pre.conf".text + "\n" + base + "\n" + c.home.configFile."hypr/hyprland.post.conf".text)')
"$hypr/bin/Hyprland" --verify-config --config "$full"
```

Result: PASS

Output summary:

```text
Config parsing result:

config ok
```

Why this command was chosen:

- It keeps the previous Hyprland syntax fix covered while changing startup wiring.

### Targeted Shell Startup Eval

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; startupHooks = builtins.filter (n: builtins.match "hey/hooks.d/startup.d/.*" n != null) (builtins.attrNames c.home.dataFile); sessionHook = c.home.dataFile."hey/hooks.d/startup.d/05-session".text; wallpaperHook = c.home.dataFile."hey/hooks.d/startup.d/10-wallpaper".text; in { preConfigHasStartupHook = builtins.match ".*exec-once = hey hook startup.*" c.home.configFile."hypr/hyprland.pre.conf".text != null; startupHooks = startupHooks; sessionHookStartsTarget = builtins.match ".*systemctl --user start hyprland-session.target.*" sessionHook != null; sessionHookStartsHyprlock = builtins.match ".*hyprlock --immediate.*" sessionHook != null; wallpaperHookStartsSwaybg = builtins.match ".*swaybg.*" wallpaperHook != null; wallpaperPath = c.modules.theme.wallpapers."*".path; dmsWantedBy = c.systemd.user.services.dms.wantedBy; dmsAfter = c.systemd.user.services.dms.after; dmsPartOf = c.systemd.user.services.dms.partOf; dmsExecStart = c.systemd.user.services.dms.serviceConfig.ExecStart; quickshellEnabled = c.modules.desktop.quickshell.enable; }'
```

Result: PASS

Output:

```json
{
  "dmsAfter": ["hyprland-session.target"],
  "dmsExecStart": "/nix/store/l8ifrgr2jdb7fi82b0fbnh1zznaxi2xy-dms-1.7.2/bin/dms run",
  "dmsPartOf": ["graphical-session.target"],
  "dmsWantedBy": ["hyprland-session.target", "graphical-session.target"],
  "preConfigHasStartupHook": true,
  "quickshellEnabled": true,
  "sessionHookStartsHyprlock": false,
  "sessionHookStartsTarget": true,
  "startupHooks": ["hey/hooks.d/startup.d/05-session", "hey/hooks.d/startup.d/10-wallpaper"],
  "wallpaperHookStartsSwaybg": true,
  "wallpaperPath": "/nix/store/c691yxx686kgy8x9vs8169giqpnb7ydl-source/modules/themes/autumnal/wallpaper.png"
}
```

Why this command was chosen:

- It directly verifies the black-screen failure path: startup now starts `hyprland-session.target`, does not foreground `hyprlock`, keeps DMS attached to the session target, and still starts wallpaper via `swaybg`.

### Regression Search

Command:

```sh
grep-equivalent search for `hyprlock --immediate`, `startup."05-loginscreen"`, session target startup, startup hook, and `swaybg` across active Nix files
```

Result: PASS

Evidence:

- No active `hyprlock --immediate` startup hook remains.
- `exec-once = hey hook startup` remains the central compositor bootstrap.
- `hey.do systemctl --user start hyprland-session.target` and `swaybg` remain in the generated startup path.

### Diff Hygiene

Command:

```sh
git diff --check
```

Result: PASS

Output: no whitespace errors.

## Skipped

- Physical `axiom` visual verification was not run from this environment. The available validation proves generated startup wiring and system build behavior, not live Quickshell rendering on the display.
