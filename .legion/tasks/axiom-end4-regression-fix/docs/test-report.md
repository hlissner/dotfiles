# Test Report: Axiom End4 Regression Fix

> Date: 2026-05-09
> Worktree: `.worktrees/axiom-end4-regression-fix/`
> Branch: `legion/axiom-end4-regression-fix-hotkeys-layout`

## Summary

PASS for repository-local validation. The live log failure was identified as incomplete end4 runtime wiring: `quickshell.service` used the wrapped package but the wrapper only included the `kirigami-wrapped` metadata package, not the actual `org.kde.kirigami` QML module files. The fix adds the Kirigami unwrapped QML module path, restores Axiom's Colemak input facts in generated Hyprland config, and adds a `Super+Space` end4 launcher/search IPC binding.

Live restart of the new package was not performed because the tested code is in a PR worktree and has not been switched into the active NixOS generation from this task.

## Failure Evidence

Command:

```sh
journalctl --user -u quickshell.service -b --no-pager -n 200
```

Result: FAIL in the active generation before this patch.

Key evidence:

```text
Started Axiom Quickshell product shell.
INFO: Launching config: "/home/c1/.config/quickshell/ii/shell.qml"
ERROR: Failed to load configuration
ERROR:   caused by @shell.qml[57:20]: Type WaffleFamily unavailable
ERROR:   caused by @modules/waffle/actionCenter/MediaPaneContent.qml[59:9]: Type FluentIcon unavailable
ERROR:   caused by @modules/waffle/looks/FluentIcon.qml[2:1]: module "org.kde.kirigami" is not installed
```

Impact: imported end4 `ii` does not load in the live session, so left sidebar/search/launcher surfaces cannot work.

## Generated Config Checks

Command:

```sh
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.home.configFile.'"hypr/custom/general.conf"'.text
```

Result: PASS.

Key evidence:

```text
input {
  kb_layout = us
  kb_variant = colemak
  kb_options = terminate:ctrl_alt_bksp
}
```

Why this matters: imported end4 `hyprland/general.conf` sets `kb_layout = us`; the generated Axiom override now restores the host XKB facts after the upstream source layer.

Command:

```sh
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.home.configFile.'"hypr/custom/keybinds.conf"'.text
```

Result: PASS.

Key evidence:

```text
bindd = Super, Space, Toggle launcher, exec, qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel
bindd = Super, A, Toggle left sidebar, exec, qs -c $qsConfig ipc call sidebarLeft toggle || true
```

Why this matters: `Super+Space` is restored as an Axiom host-level launcher/search entrypoint without reverting to the old shell; `Super+A` has a direct IPC route to the imported end4 left sidebar.

## Quickshell Package Checks

Command:

```sh
env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.modules.desktop.quickshell.package --no-link
```

Result: PASS.

Command:

```sh
env -u DOTFILES_HOME nix eval --impure --raw .#nixosConfigurations.axiom.config.modules.desktop.quickshell.package
```

Result: PASS.

Key evidence:

```text
/nix/store/qi1qd26kqg39mb0x3b87yqbdlzjzw45a-axiom-quickshell
```

Command:

```sh
test -d /nix/store/b4hk5nisny0fj9gk41jxpp6205j8jpwb-kirigami-6.22.0/lib/qt-6/qml/org/kde/kirigami
```

Result: PASS.

Why this matters: the new wrapper QML path includes the actual Kirigami QML module tree required by `config/quickshell/ii/modules/waffle/looks/FluentIcon.qml`.

Command:

```sh
env -u DOTFILES_HOME nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.quickshell.serviceConfig.ExecStart
```

Result: PASS.

Key evidence:

```text
"/nix/store/qi1qd26kqg39mb0x3b87yqbdlzjzw45a-axiom-quickshell/bin/quickshell --config ii"
```

## Headless Smoke

Command:

```sh
env -u DOTFILES_HOME QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME=... XDG_STATE_HOME=... XDG_CACHE_HOME=... timeout 8s /nix/store/qi1qd26kqg39mb0x3b87yqbdlzjzw45a-axiom-quickshell/bin/quickshell --config ii
```

Result: expected headless limitation.

Key evidence:

```text
INFO: Launching config: ".../config/quickshell/ii/shell.qml"
ERROR: Failed to load configuration
ERROR:   caused by @shell.qml[23:5]: Type ReloadPopup unavailable
ERROR:   caused by @ReloadPopup.qml[35:3]: No PanelWindow backend loaded.
```

Why this matters: the smoke reaches the imported `ii` entrypoint and fails at the known offscreen compositor backend limitation, not at the previously observed live Kirigami failure.

## Axiom Toplevel Build

Command:

```sh
env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

## Warnings

The Nix commands emitted existing repository/channel warnings:

- `specialArgs.pkgs` means some nixpkgs options/overlays are ignored.
- `mesa.drivers` is deprecated.
- `hardware.pulseaudio` has been renamed to `services.pulseaudio`.
- `system` has been renamed to/replaced by `stdenv.hostPlatform.system`.

These warnings did not prevent the final build.

## Skipped Live Checks

- The new package was not restarted in the live graphical session because the fix is still in this PR worktree and not switched into the active NixOS generation.
- After deployment, run `systemctl --user restart quickshell.service` or trigger the normal reload hook, then verify `journalctl --user -u quickshell.service -b` no longer reports `org.kde.kirigami` missing.
- After deployment, verify `Super+Space`, `Super+A`, and Colemak behavior in the actual Hyprland session.
