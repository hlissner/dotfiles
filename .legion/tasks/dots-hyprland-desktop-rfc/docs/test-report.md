# Test Report: Complete Axiom End4 Import

> Date: 2026-05-09
> Worktree: `.worktrees/dots-hyprland-desktop-rfc/`
> Branch: `legion/dots-hyprland-desktop-rfc-end4-complete`

## Summary

PASS for repository-local validation. Live Wayland restart was skipped because this shell is on host `axiom` but not inside a graphical Hyprland session.

The strongest checks prove that Axiom now builds with the imported end4 `ii` source, defaults Quickshell to `ii`, links the adjacent matugen/fuzzel/Hyprland sources, generates Axiom host overrides through Nix, omits generated color outputs, and resolves local QML imports including the required rounded-polygon submodule.

## Environment

Command:

```sh
hostname && printf 'XDG_SESSION_TYPE=%s\nWAYLAND_DISPLAY=%s\nHYPRLAND_INSTANCE_SIGNATURE=%s\n' "${XDG_SESSION_TYPE-}" "${WAYLAND_DISPLAY-}" "${HYPRLAND_INSTANCE_SIGNATURE-}"
```

Result:

```text
axiom
XDG_SESSION_TYPE=tty
WAYLAND_DISPLAY=
HYPRLAND_INSTANCE_SIGNATURE=
```

Why this command was chosen: the contract requires distinguishing host identity from live compositor/session availability.

## Commands

### Entrypoint Source Check

Command:

```sh
test -f 'config/quickshell/ii/shell.qml' && rg --fixed-strings 'IllogicalImpulseFamily' 'config/quickshell/ii/shell.qml'
```

Result: PASS.

Key evidence:

```text
component: IllogicalImpulseFamily {}
```

### Targeted Nix Runtime Wiring

Command:

```sh
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.modules.desktop.quickshell.configName
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.quickshell.serviceConfig.ExecStart
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.home.configFile.'"quickshell/ii"'.source
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.home.configFile.'"matugen"'.source
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.home.configFile.'"hypr/custom/variables.conf"'.text
```

Result: PASS.

Key evidence:

```text
"ii"
"/nix/store/...-axiom-quickshell/bin/quickshell --config ii"
"/nix/store/...-source/config/quickshell/ii"
"/nix/store/...-source/config/matugen"
$qsConfig = ii
$dontLoadDefaultExecs = 1
```

Why these commands were chosen: they directly prove the active runtime config and Nix-generated override boundary.

### QML Local Import Scan

Command:

```sh
python3 - <<'PY'
from pathlib import Path
import re
root = Path('config/quickshell/ii')
missing = []
for path in root.rglob('*.qml'):
    for lineno, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        stripped = line.strip()
        m = re.match(r'import\s+"([^"]+)"', stripped)
        if m:
            target = (path.parent / m.group(1)).resolve()
            if not target.exists():
                missing.append(f'{path}:{lineno}: missing relative import {m.group(1)}')
            continue
        m = re.match(r'import\s+qs(?:\.([A-Za-z0-9_.]+))?(?:\s+as\s+\w+)?\s*$', stripped)
        if m:
            suffix = m.group(1)
            target = root if not suffix else root.joinpath(*suffix.split('.'))
            if not target.exists():
                missing.append(f'{path}:{lineno}: missing qs import {stripped}')
if missing:
    print('\n'.join(missing))
    raise SystemExit(1)
print('checked qml files:', sum(1 for _ in root.rglob('*.qml')))
print('missing local imports: 0')
PY
```

Result: PASS.

Key evidence:

```text
checked qml files: 577
missing local imports: 0
```

Why this command was chosen: it validates the imported source tree has the local `qs.*` and quoted QML imports required for static loadability without a compositor.

### Generated Output And Secret Scans

Commands:

```sh
test ! -e 'config/hypr/hyprland/colors.conf'
test ! -e 'config/hypr/hyprlock/colors.conf'
test ! -e 'config/fuzzel/fuzzel_theme.ini'

if rg --pcre2 '(AIza[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z_-]{20,}|-----BEGIN (RSA|OPENSSH|PRIVATE)|ghp_[0-9A-Za-z_]{20,}|github_pat_[0-9A-Za-z_]+)' 'config' '.legion/tasks/dots-hyprland-desktop-rfc/docs/import-manifest.md'; then exit 1; else exit 0; fi
```

Result: PASS.

Why these commands were chosen: the import boundary explicitly excludes generated color outputs and common committed-secret patterns.

### Wrapped Quickshell Package Build

Command:

```sh
env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.modules.desktop.quickshell.package --no-link
```

Result: PASS.

Why this command was chosen: imported `ii` requires Quickshell service modules not present in the pinned `0.2.1`; the wrapped package now builds Quickshell `0.3.0` with the needed QML/service import paths.

### Headless Quickshell Smoke

Command:

```sh
qs_pkg=$(env -u DOTFILES_HOME nix eval --impure --raw .#nixosConfigurations.axiom.config.modules.desktop.quickshell.package)
smoke='.legion/tasks/dots-hyprland-desktop-rfc/tmp/quickshell-offscreen'
rm -rf "$smoke"
mkdir -p "$smoke/config/quickshell" "$smoke/state" "$smoke/cache"
ln -s "$PWD/config/quickshell/ii" "$smoke/config/quickshell/ii"
ln -s "$PWD/config/matugen" "$smoke/config/matugen"
ln -s "$PWD/config/fuzzel" "$smoke/config/fuzzel"
ln -s "$PWD/config/hypr" "$smoke/config/hypr"
env -u DOTFILES_HOME QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$PWD/$smoke/config" XDG_STATE_HOME="$PWD/$smoke/state" XDG_CACHE_HOME="$PWD/$smoke/cache" timeout 8s "$qs_pkg/bin/quickshell" --config ii
code=$?
rm -rf "$smoke"
exit $code
```

Result: expected headless failure after loading the `ii` entrypoint and resolving QML imports.

Key evidence:

```text
INFO: Launching config: ".../tmp/quickshell-offscreen/config/quickshell/ii/shell.qml"
ERROR: Failed to load configuration
caused by @ReloadPopup.qml[35:3]: No PanelWindow backend loaded.
```

Why this command was chosen: it is the strongest available Quickshell loadability check without a Wayland/layershell backend. The failure reached a compositor/backend limitation rather than missing `ii`, missing local QML files, `Qt5Compat`, or `Quickshell.Services.Polkit`.

### Axiom Toplevel Build

Command:

```sh
env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

Why this command was chosen: it is the strongest repository-local proof that the imported source, NixOS modules, user services, packages, generated home config files, and Axiom host facts compose into a buildable system.

## Failures Found And Fixed

- Static QML scan initially failed because upstream `ii/modules/common/widgets/shapes` is a git submodule. Fix: imported `end-4/rounded-polygon-qmljs` at `e31ec4cb4ebf6a46b267f5c42eabf6874916fa16` without `.git` metadata.
- The first full build used stale `DOTFILES_HOME=/nix/store/8mx5...-source`, so Nix looked at an old flake source missing `config/fuzzel`. Fix: run validation with `env -u DOTFILES_HOME`; staged new source files so Git-backed flake evaluation includes them.
- Offscreen Quickshell smoke initially failed on `Qt5Compat.GraphicalEffects`. Fix: wrap `quickshell` and `qs` with QML/plugin paths from Qt runtime dependencies.
- Offscreen Quickshell smoke then failed on missing `Quickshell.Services.Polkit` because pinned `quickshell 0.2.1` lacks that service module. Fix: build Quickshell `0.3.0` from upstream tag `v0.3.0` with `glib`, `polkit`, and `cpptrace` inputs.
- Quickshell `0.3.0` initially failed the local `cpptrace` signal-safe unwind check. Fix: set `DO_NOT_CHECK_CPPTRACE_USABILITY=true`, matching the package need without vendoring network-fetched sources during build.

## Warnings

The Nix commands emitted existing repository/channel warnings:

- `specialArgs.pkgs` means some nixpkgs options/overlays are ignored.
- `mesa.drivers` is deprecated.
- `hardware.pulseaudio` has been renamed to `services.pulseaudio`.
- `system` has been renamed to/replaced by `stdenv.hostPlatform.system`.

These warnings did not prevent evaluation or the final toplevel build.

## Skipped Runtime Checks

- `systemctl --user restart quickshell.service` was not run because `XDG_SESSION_TYPE=tty`, `WAYLAND_DISPLAY` is empty, and `HYPRLAND_INSTANCE_SIGNATURE` is empty.
- Hardware-backed UI behavior for audio, brightness, DDC, network, Bluetooth, power profile, tray, notifications, sidebars, overview, launcher, lock/session, and wallpaper switching was not exercised live from this TTY shell.

## Conclusion

The implementation passes repository-local validation for the complete end4 import. Remaining risk is live Wayland/Hyprland behavior, which must be checked from the actual graphical Axiom user session.
