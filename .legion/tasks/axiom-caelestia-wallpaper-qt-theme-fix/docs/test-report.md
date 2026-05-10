# Test Report: Axiom Caelestia Wallpaper Qt Theme Fix

## Summary

PASS. Static Nix validation and the wallpaper conversion command both passed. Live graphical validation still requires deployment and a Hyprland restart because the icon workaround depends on process environment inheritance and the wallpaper render path is graphical.

## Commands

### Targeted Generated Config Eval

Command:

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; userName = cfg.user.name; in { hyprEnv = cfg.home.file.".config/hypr/custom/env.conf".text; uwsmEnv = cfg.home.file.".config/uwsm/env".text; serviceEnv = cfg.systemd.user.services.caelestia-shell.environment; startupHook = cfg.hey.hooks.startup."05-session"; execStartPre = cfg.systemd.user.services.caelestia-shell.serviceConfig.ExecStartPre; qt6ctInUserPackages = builtins.any (p: (p.pname or "") == "qt6ct") cfg.users.users.${userName}.packages; }'
```

Result: PASS.

Evidence:

- `hyprEnv` contains `env = QT_QPA_PLATFORMTHEME,qt6ct`.
- `uwsmEnv` contains `export QT_QPA_PLATFORMTHEME=qt6ct`.
- `serviceEnv` contains `QT_QPA_PLATFORMTHEME = "qt6ct"` and `QT_QPA_PLATFORM = "wayland"`.
- `startupHook` imports `QT_QPA_PLATFORMTHEME` into the systemd user manager environment.
- `qt6ctInUserPackages = true`.
- `execStartPre` resolves to `/nix/store/sf8b576x63l8yjndx5pvk0zba0k0aq7r-caelestia-seed-wallpaper`.

Why this command: it directly proves the generated values that implement the Qt icon workaround and service pre-start hook without requiring a live graphical restart.

### Axiom Toplevel Build

Command:

```sh
nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure
```

Result: PASS.

Evidence:

- The Axiom toplevel built successfully.
- The build realized the generated Hyprland env, UWSM env, Caelestia seed script, Caelestia user unit, user environment, and system toplevel derivations.
- Existing warnings were non-blocking and unrelated to this task: read-only eval-cache writes, `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` attribute warnings.

Why this command: it validates the changed Nix modules together in the actual Axiom host configuration, including the new `qt6ct` package dependency and generated systemd/home-manager artifacts.

### Wallpaper Conversion Smoke Test

Command:

```sh
out=".legion/tasks/axiom-caelestia-wallpaper-qt-theme-fix/docs/generated-test.jpg" && /nix/store/kya6l24s9861ihbzx1a03665xdg3zvx6-imagemagick-7.1.2-10/bin/magick /home/c1/the-great-sage.jpg -auto-orient -resize '3840x2160>' -strip -quality 92 "$out" && /nix/store/kya6l24s9861ihbzx1a03665xdg3zvx6-imagemagick-7.1.2-10/bin/magick identify -format '%w %h %b\n' "$out" && rm "$out"
```

Result: PASS.

Evidence:

```text
3840 1858 757392B
```

Why this command: it proves the same ImageMagick transform used by the service pre-start script can decode the source wallpaper and produce a much smaller derivative. The temporary output was created under the task docs directory and removed after identification.

## Generated Script Inspection

After the toplevel build, the generated `caelestia-seed-wallpaper` script was read from the Nix store. It:

- Creates `/home/c1/.local/state/caelestia/wallpaper`.
- Generates `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` from `/home/c1/the-great-sage.jpg` when missing or stale.
- Uses ImageMagick with `-auto-orient -resize '3840x2160>' -strip -quality 92`.
- Writes `path.txt` only when the current state is missing, empty, or still equals `/home/c1/the-great-sage.jpg`.

## Skipped Live Validation

Not run in this phase:

- Restarting Hyprland.
- Running the Caelestia service pre-start script against the live state directory.
- Opening the launcher to visually confirm icon rendering.

Reason: these mutate or depend on the active graphical session. They should be run after deployment from the merged PR.

Expected live checks after deployment:

- `cat /home/c1/.local/state/caelestia/wallpaper/path.txt` points at `/home/c1/.local/state/caelestia/wallpaper/generated.jpg`, unless the user manually selected another wallpaper.
- Caelestia logs no longer show the Qt image allocation rejection for the active wallpaper.
- `pgrep -a swaybg` returns no wallpaper owner process.
- Exactly one Caelestia quickshell instance is active.
- Launcher icons no longer render as color blocks after Hyprland restart.
