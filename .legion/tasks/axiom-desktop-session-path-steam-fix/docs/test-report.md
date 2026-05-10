# Test Report: Axiom Desktop Session PATH And Steam Fix

## Result
PASS. Targeted evals confirm the generated graphical session path, systemd-user environment import, Caelestia service path coverage, and Steam enablement. The full `axiom` NixOS toplevel build also succeeds.

## Why These Checks
The change is declarative NixOS/session wiring, so generated configuration is the strongest local evidence available. Physical GUI behavior still requires a fresh `axiom` Hyprland/UWSM session after deployment.

## Commands

### Generated UWSM Env
Command:

```sh
DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.home.configFile.'"uwsm/env"'.text --raw
```

Result: PASS.

Evidence:

```text
export PATH=/home/c1/.local/bin:/etc/profiles/per-user/c1/bin:/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export NIXOS_OZONE_WL=1
export MOZ_ENABLE_WAYLAND=1
export GTK_USE_PORTAL=1
export QT_QPA_PLATFORMTHEME=qt6ct
```

### Hyprland Startup Hook
Command:

```sh
DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.hey.hooks.startup.'"05-session"' --raw
```

Result: PASS.

Evidence:

```text
hey.do systemctl --user import-environment \
       DISPLAY WAYLAND_DISPLAY \
       PATH \
       XDG_CURRENT_DESKTOP \
       QT_QPA_PLATFORMTHEME \
       HYPRLAND_INSTANCE_SIGNATURE
hey.do systemctl --user start hyprland-session.target
hey .play-sound startup
```

### Caelestia Service Path
Command:

```sh
DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.path --apply 'packages: builtins.filter (name: name == "git" || name == "gawk" || name == "steam" || name == "steam-run" || name == "app2unit") (builtins.map (pkg: pkg.pname or pkg.name or "") packages)' --json
```

Result: PASS.

Evidence:

```json
["app2unit","app2unit","git","steam","steam-run","gawk"]
```

### Steam Enablement
Command:

```sh
DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.programs.steam.enable --json
```

Result: PASS.

Evidence:

```json
true
```

### Diff Whitespace
Command:

```sh
git diff --check
```

Result: PASS; no output.

### Full Axiom Build
Command:

```sh
DOTFILES_HOME="$PWD" nix build --impure --no-link path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS; produced `/nix/store/9gdi1kl212slpxiwbjmpkv410gi3kpkm-nixos-system-axiom-25.11.20260203.e576e3c.drv`.

## Non-blocking Warnings
- Nix emitted existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` usage. These warnings are unrelated to the PATH/session change and did not fail eval or build.

## Deployment Checks
- After switching on `axiom`, start a fresh Hyprland/UWSM session.
- Open Foot from the GUI and run `echo $PATH`, `command -v git`, and `command -v awk`.
- Launch Steam from the GUI. If it still fails, capture Steam logs and split the remaining issue into a Steam runtime follow-up rather than expanding this PATH task.
