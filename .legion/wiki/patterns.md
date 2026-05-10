# Patterns

## Git Flake Validation With New Modules

When validating a Git-backed flake after adding new module files, mark those files as tracked or intent-to-add before running `nix eval`/`nix build`. Otherwise Nix may evaluate the Git source without untracked module files, and `_module.check = false` can hide missing option declarations.

Recommended pre-validation command shape:

```sh
git add -N <new-module-files>
```

The final commit must still add the files normally.

When validating an impure flake from a nested PR worktree, set `DOTFILES_HOME` to the worktree path and prefer a `path:` flake reference to that worktree. A stale ambient `DOTFILES_HOME` can cause generated Home Manager sources to point at an older Nix store snapshot even when the command is run from the intended worktree.

## Runtime Entry Validation

For display-manager runtime regressions, validate the effective NixOS session data rather than guessing desktop entry names. Check `services.displayManager.sessionData.sessionNames`, the generated `share/wayland-sessions/*.desktop` entries, and the consumer command that references them.

For NetworkManager/iwd changes, validate service ownership explicitly: NetworkManager backend/DNS, iwd `EnableNetworkConfiguration`, resolved enablement, legacy DHCP service presence, and any generated NetworkManager ensure profiles.

For Hyprland config syntax migrations, do not rely on Nix build/eval alone. Build a combined config from generated pre config, checked-in base config, and generated post/theme config, then run the evaluated Hyprland binary with `--verify-config`.

For visible-shell startup regressions where Hyprland shows a cursor but the desktop stays black, validate the generated startup chain directly. Check that `exec-once = hey hook startup` is present, startup hooks are ordered as expected, the early session hook starts `hyprland-session.target`, DMS/Quickshell is wanted by the session target, wallpaper starts through the configured background hook, and no foreground lock command gates the shell path.

For Hyprland/UWSM startup warnings, validate the actual command resolution instead of only checking desktop entry existence. A `uwsm start` dry run should resolve to `start-hyprland`; if it resolves to direct `Hyprland`, the generated startup path can still trigger the upstream warning even when UWSM is present.

For autossh reverse tunnel regressions, validate both sides of the generated shape: the remote-forward string must remain loopback-only and port-unique, and the local target service must exist as an active daemon if the tunnel forwards to `127.0.0.1:22`.

For terminal config compatibility regressions, validate the repository source and the Nix-evaluated Home Manager source path with the target terminal binary. For Foot, `foot --check-config --config <path>` is the direct validation surface; do not assume an option remains valid across package upgrades just because an older checked-in config accepted it.

For GUI-launched terminal or app command lookup regressions that do not reproduce over SSH, validate graphical session PATH ownership rather than patching shell rc files first. Check generated `uwsm/env`, the Hyprland startup `systemctl --user import-environment` list, relevant launcher service `path` entries, and whether the missing commands live in `config.environment.systemPackages` or user packages.

For out-of-band user tools such as opencode under `$HOME/.opencode/bin`, validate both interactive shell startup and generated desktop session PATH. Avoid literal `environment.variables.PATH` strings as the only integration surface; prefer explicit shell path initialization plus generated `uwsm/env` evidence.

For Steam HiDPI regressions on fractional-scale Hyprland, validate both compositor and application surfaces: generated `xwayland.force_zero_scaling`, the actual wrapped `bin/steam` script exporting `STEAM_FORCE_DESKTOPUI_SCALING`, Steam package closure presence, assembled `Hyprland --verify-config`, and the host toplevel build. Live crispness remains a deployment smoke check.

For NixOS GUI apps that also ship service/TUN installers, prefer the upstream NixOS module over mutable GUI installer flows. Validate the actual exposed option names with `nix eval ...options.<module> --apply builtins.attrNames`, because this repository disables strict module option checking and inert settings can otherwise be silently ignored.

For Clash Verge Rev specifically, validate `programs.clash-verge.serviceMode`, `tunMode`, `autoStart`, the generated `clash-verge.service` `ExecStart`, capability bounding set, `networking.firewall.trustedInterfaces`, `extraReversePathFilterRules`, and the host `system.build.toplevel.drvPath`.

## 上游桌面参考采用模式

使用大型外部桌面 dotfiles 仓库作为产品灵感时，应先提取能力，再考虑代码移动。需要把 compositor/session model、shell ownership、notification/search/control surfaces、theming、state writes、dependency assumptions 和 rollback boundaries 与 Axiom 当前 Nix-native model 对比。

不要导入 mutable installers、distro package-manager logic、generated user state，或与 Axiom UWSM/systemd ownership 冲突的 session assumptions。优先采用分阶段本地能力等价；在 shell-native replacements 验证前，保留外部工具作为 fallback。

## Quickshell Notification Center Pattern

For Axiom notification UI, keep `NotificationServer` as the ingress and use `trackedNotifications` as the runtime source of truth. Keep notification history session-local unless a task explicitly defines retention, clear behavior, disable switches, and privacy handling.

When validating new Quickshell QML files from a Git-backed flake, stage or intent-to-add the new files before `nix eval`/`nix build`, then pair Nix build evidence with a real-session test plan. Headless/offscreen Quickshell can fail at `No PanelWindow backend loaded`; treat that as an environment limitation, not a substitute for Hyprland layer-shell testing.

Keep Quickshell `Variants` composition simple: use one per-screen `PanelWindow` delegate per `Variants` block. If multiple windows need the same screen model, create separate `Variants` blocks or an explicit wrapper component; do not add sibling `PanelWindow` delegates in one `Variants` block.

## Quickshell Search and Actions Pattern

For Axiom shell-owned search/actions, keep the visible UI in Quickshell and keep provider execution behind fixed local verbs. QML may compose results and invoke reviewed argv arrays or repository-owned helper subcommands, but it should not parse desktop-entry `Exec` strings into shell commands or pass user query text to `sh -lc`.

Search providers should be independently bounded: app launch validates desktop IDs against scanned entries, calculator input is parsed as data through a restricted expression evaluator or equivalent local backend, emoji data stays local/offline, web search only opens an encoded user-requested URL, and clipboard history has explicit caps, clear, disable, and rollback behavior.

Fallback-first rollout remains required for launcher replacements. Keep Fuzzel available through a direct action and binding until the Quickshell search panel, IPC/focus behavior, and real app/clipboard actions are verified in an Axiom Wayland session.

When verifying Quickshell search changes headlessly, treat Nix eval/build, helper smoke tests, scope grep, `git diff --check`, and `Hyprland --verify-config` as useful evidence, but record that `PanelWindow` runtime behavior still requires a real layer-shell session.

## Quickshell Quick Controls and OSD Pattern

For Axiom quick controls, prefer a Quickshell-owned panel plus a narrow fixed-verb helper over deep QML/DBus control-center logic. The first pass should show useful status, expose common safe actions, and keep full settings apps as visible fallbacks rather than implementing Wi-Fi onboarding, Bluetooth pairing, or audio device switching in one task.

OSD wrappers must preserve the underlying state change before attempting shell polish. Volume and brightness can continue through `hey .osd` / `pamixer` / `brightnessctl`; media key wrappers should run fixed `playerctl` verbs before attempting Quickshell IPC. If IPC or Quickshell fails, existing `notify-send` or direct command fallback remains the rollback path.

For verification, pair static checks (`qmllint`, helper syntax/smoke, `zsh -n`, Nix eval/build, `Hyprland --verify-config`, scope/fallback greps, and `Variants`/`PanelWindow` counts) with a live-session checklist. Headless validation cannot prove panel focus, layer placement, rapid OSD timing, or disruptive actions such as Wi-Fi/Bluetooth toggles, lock, DPMS off, and `wlogout`.

## Caelestia Shell Integration Pattern

When adopting Caelestia Shell on Axiom, consume the upstream `caelestia-dots/shell` flake package instead of vendoring shell source or running mutable setup scripts. Prefer `packages.<system>.with-cli`, because the upstream default package omits full CLI support.

Keep a small local NixOS integration module as the repository boundary: install the shell and CLI package, write minimal `caelestia/shell.json`, start `caelestia-shell.service` under `hyprland-session.target`, and keep reload/restart hooks inside the repo's existing session ownership model.

When Caelestia owns wallpaper, keep it as the only wallpaper owner. Gate the Hyprland `swaybg` hook off, enable `background.wallpaperEnabled` in generated `caelestia/shell.json`, and seed the mutable Caelestia wallpaper state from service startup. If the canonical wallpaper is too large for Qt image IO, generate a display-safe derivative under Caelestia's state directory and update `path.txt` only when it is missing, empty, or still points at the known oversized source.

Caelestia Shell is a launcher and helper process parent, so its user service needs an explicit runtime PATH that includes `app2unit`, CLI/helper tools such as `util-linux`, user application packages, and generated system packages when those packages provide desktop-entry commands or terminal-visible tools. Nix build success alone does not prove launcher subprocesses can start if the systemd service PATH is still minimal.

Prevent duplicate shell ownership by using quickshell `--no-duplicate` and systemd-owned restart/stop commands. Avoid Hyprland keybinds that directly launch the shell binary, because they create unmanaged instances outside `caelestia-shell.service`.

Expose standard desktop icon and MIME fallback packages with the local Caelestia integration when the shell is the active product surface. `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils` should be in the Axiom user package closure so Qt/app launcher/tray icon lookup does not fall back to checkerboard placeholders.

For Caelestia launcher icon color-block regressions matching upstream issue #1282, set `QT_QPA_PLATFORMTHEME=qt6ct` in generated Hyprland env, generated UWSM env, the Caelestia user service environment, and the systemd user import path. Install `qt6ct` from the Qt 6 package set used by the desktop stack, and validate after a full Hyprland restart rather than relying on config reload alone.

Use the checked-in Hyprland file as a local base that sources only repository-owned generated config. Host facts such as XKB, monitors, workspaces, rules, default apps, session startup, and fallback keybinds belong in generated `hypr/custom/*.conf` files rather than in upstream shell source or live-home edits.

Validate Caelestia migrations by evaluating the upstream `with-cli` package, generated service command, generated `caelestia/shell.json`, user package closure, active Hyprland keybinds, and absence of active end4 references outside historical `.legion/tasks/**`. Always run an assembled `Hyprland --verify-config` after changing generated keybinds or rules; Nix build alone does not catch parser restrictions such as top-level `catchall`. Pair static evidence with a live Hyprland session smoke when available; headless builds cannot prove layer-shell rendering, tray, launcher focus, icon rendering, OSD, screenshot, or lock/session behavior.

When Caelestia global-shortcut dispatch is the reported failure, prefer reviewed CLI IPC keybinds for drawers, brightness, media, and picker actions over reworking DBus/global-shortcut plumbing in the same hotfix. Validate command names against the current Caelestia package source or `caelestia shell -s`, and keep direct shell process starts out of Hyprland keybinds.

For Caelestia lock/session regressions, treat `loginctl lock-session` as a separate integration path from direct `hyprlock`. If logind-triggered Caelestia lock handling crashes, route ordinary idle/keybind locks to `hyprlock` while keeping a live-session follow-up to confirm lock-before-sleep behavior.

## Historical End4 Desktop Import Pattern

When adopting end4 desktop phases in Axiom, treat the upstream `ii` source tree as product source once substrate-only is rejected. Import required upstream files through a manifest, record upstream commits and submodules, and keep omitted installer/generated/secret/state paths explicit.

The target UX can be end4 `ii` / `IllogicalImpulseFamily`, but Nix must still own host facts, UWSM/greetd/portal startup, package closure, system services, user services, groups, kernel modules, keyring/polkit, generated override files, and generated-state boundaries.

Do not use old Axiom shell affordances as compatibility requirements once an end4 phase explicitly supersedes them. It is acceptable to keep transitional helper code alive for currently checked-in shell sources, but task docs and wiki must mark that code as migration debt rather than current product truth.

For large QML imports, pair Nix eval/build with a local QML import scan and a bounded headless Quickshell smoke. If the smoke reaches `ii/shell.qml` and then fails at `No PanelWindow backend loaded`, record that as a TTY/offscreen compositor limitation, not as live layer-shell validation.

For imported end4 QML dependencies, validate that wrapper paths contain real module trees. KDE package names can point at wrapper/metadata derivations; if QML imports fail at runtime, add the corresponding unwrapped QML package path and export both `QML2_IMPORT_PATH` and `QML_IMPORT_PATH` from the wrapper.

Keep host-level Hyprland facts in generated `hypr/custom/*.conf` files sourced after upstream end4 config. This is the right layer for Axiom XKB layout/variant/options and host hotkeys such as end4 search/sidebar IPC bindings, because imported upstream defaults may otherwise override local workstation facts.

For `cliphist` adoption, distinguish shell display/readback limits from database retention. `wl-paste --watch cliphist store` proves the backend wiring, but privacy readiness still requires a retention/clear policy and live-session verification.

For end4 live-polish fixes, validate process integration as well as QML imports. Check generated Hyprland bindings, Quickshell IPC targets, service `ExecStart`, service PATH package closure, wallpaper/theme output directories, and the Home Manager source path before relying on live smoke tests.

Use real no-op IPC liveness handlers for fallback probes. A missing or placeholder target can make every fallback path run even while Quickshell is alive, which can hide the intended panel and launch unrelated tools.

When imported shell code writes preview images, screenshots, clipboard decodes, or generated theme state, prefer XDG cache/state paths and ensure parent directories exist before helper processes run. Avoid shared `/tmp` paths for persistent shell integration unless a task explicitly scopes cleanup and collision behavior.
