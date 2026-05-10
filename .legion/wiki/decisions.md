# Decisions

## Linux Workstation Desktop Baseline

Current Axiom Linux workstation desktop direction is Hyprland + UWSM + NixOS-owned desktop integration, with Zen as the browser baseline, mpv as the scoped media player, Vesktop/Discord as the scoped chat app, Steam Gamescope/Gamemode/Umu tuning, NetworkManager+iwd+resolved for workstation Wi-Fi, and BlueZ/Blueman reliability settings.

Caelestia Shell supersedes the previous repository-managed end4 `ii` desktop direction for Axiom. The active product shell is now the upstream Caelestia shell package with CLI support, integrated by a local NixOS module, while NixOS keeps ownership of UWSM/greetd/portal startup, Hyprland host facts, systemd user service wiring, generated XDG config, rollback, and Darwin isolation.

Axiom must use the upstream `caelestia-dots/shell` flake package output `packages.<system>.with-cli` for the desktop shell. Do not run Caelestia's mutable setup flow, clone live shell source under `~/.config`, or preserve end4 as a fallback product path unless a future task explicitly reopens that architecture.

The active shell service is `caelestia-shell.service` under `hyprland-session.target`, with `ExecStart` pointing to `${caelestiaPackage}/bin/caelestia-shell`. Repository-generated config should stay minimal, for example `caelestia/shell.json` with local app defaults and dangerous launcher actions disabled; exhaustive upstream defaults should be left to upstream.

On Axiom, Caelestia owns wallpaper for the Caelestia desktop session. Do not run the old Hyprland `swaybg` wallpaper hook when `modules.desktop.caelestia.wallpaper.enable` is true. Seed Caelestia's mutable wallpaper state from service startup; do not manage `~/.local/state/caelestia/wallpaper/path.txt` as an immutable home-manager file. If the canonical wallpaper source exceeds Qt image decode limits, point Caelestia at a generated decode-safe derivative while preserving the canonical host source.

For Caelestia launcher icon color-block regressions matching upstream `caelestia-dots/shell#1282`, Axiom should use `QT_QPA_PLATFORMTHEME=qt6ct` in the repo-owned Hyprland/UWSM/service environment and include `qt6ct` in the user package closure. A full Hyprland restart is required to validate this environment change.

`caelestia-shell.service` must run with duplicate-instance protection and a PATH that can execute launcher/runtime helpers. Keep shell stop/restart paths inside `systemctl --user`; do not spawn `${caelestiaShell}` directly from Hyprland keybinds because unmanaged quickshell instances can duplicate layers and global shortcuts.

Until Caelestia's logind lock crash is proven fixed, ordinary Axiom idle/keybind lock paths should call `hyprlock` directly rather than `loginctl lock-session` or `caelestia:lock`.

Axiom-specific input facts, monitors, workspaces, app rules, environment, and fallback keybinds remain Nix-generated Hyprland config. Primary shell bindings should target Caelestia global shortcuts or reviewed Caelestia CLI commands, not legacy `quickshell --config ii`, end4 IPC names, `IllogicalImpulse`, matugen, or fuzzel shell assumptions.

Axiom notification center 的第一个实现切片采用 session-local Quickshell panel：使用 `NotificationServer.trackedNotifications` 管理当前会话通知，dock button 负责打开 panel，通知内容不持久化。后续不得在没有 retention、clear、disable 和 privacy policy 的情况下把 notification history 或 clipboard history 落盘。

Axiom Stage 2 search/actions 采用 Quickshell-owned panel，而不是恢复 Rofi/DMS primary path 或导入上游 launcher framework。`APP` dock entry 和 primary launcher binding should open Quickshell search first, while Fuzzel remains installed and directly reachable as fallback. Search providers must execute through fixed verbs, reviewed argv arrays, or repository-owned helper subcommands; user query text must not become shell script.

Axiom clipboard history is now allowed for the Stage 2 search surface because this single-user workstation task explicitly chose function completeness. The allowed shape is bounded user-local persistence with finite entry/size caps, visible clear-history behavior, a Nix-owned disable path, and rollback by clearing state or disabling `modules.desktop.quickshell.search.clipboard.enable`.

Axiom Stage 3 quick controls and OSD use a Quickshell-owned panel plus fixed-verb local helper, not deep DBus/control-center parity. The panel may expose shallow status and common actions for audio, network, Bluetooth, media, brightness, power profiles, session/power, resource status, and basic desktop actions, but external tools (`nm-connection-editor`, `blueman-manager`, `pavucontrol`, `wlogout`, `playerctl`, Fuzzel/direct commands) remain the fallback and full-management path until end4 `ii` replaces the transitional shell.

Axiom OSD feedback should prefer Quickshell IPC for volume/brightness/media display while preserving existing state-changing commands. Volume and brightness continue through `hey .osd` wrappers, and media keys may route through `axiom-control-helper media ...`; if Quickshell IPC is unavailable, notify/direct command fallback must keep the key behavior operational.

Old X11/bspwm/sxhkd/Polybar/Dunst/Waybar/legacy-idle/browser/media/Spotify compatibility is not preserved unless a future task explicitly reopens that scope.

Hyprland display-manager wiring should start through UWSM and resolve to the evaluated `start-hyprland` launcher path. Do not point greetd at `hyprland-uwsm.desktop` when that path reparses to direct `Hyprland`, because Hyprland 0.53 warns that direct startup without `start-hyprland` is only appropriate for debugging.

Hyprland 0.53 active configuration must use the current `windowrule`/`layerrule` syntax. `windowrulev2` is a parse error in the evaluated Hyprland 0.53.3 package, and old layer-rule spellings such as `noanim`, `dimaround`, `ignorezero`, and `ignorealpha` should not be used in active config.

Hyprland startup must bootstrap the visible product session before lock-screen or visual hooks can block it. The active startup path is `exec-once = hey hook startup`; the early hook imports compositor environment variables and starts `hyprland-session.target`, while wallpaper remains a later hook. Do not restore foreground `hyprlock --immediate` as a startup gate for DMS/Quickshell or wallpaper; use a real greeter or non-blocking lock flow in a future scoped task if boot-time physical access protection is required.

When NetworkManager uses iwd as the Wi-Fi backend, NetworkManager owns DHCP/routes. iwd's built-in network configuration should stay disabled, and workstation wired DHCP/autoconnect should be modeled through NetworkManager profiles rather than legacy `dhcpcd`. Do not globally set NetworkManager `no-auto-default=*` for workstations unless every required link has a known-good explicit profile, because it can block fallback default connection creation.

## Darwin Boundary

Darwin remains a shared shell/dev/editor/XDG target. Linux desktop/system concerns such as Hyprland, DMS/Quickshell, Steam, NetworkManager/iwd, BlueZ/Blueman, portals, and display-manager wiring must stay out of Darwin imports unless a future Darwin-specific task changes the contract.

## Reverse SSH Tunnels

Current autossh reverse tunnels to `root@8.159.128.125` bind remote loopback explicitly and forward back to each host's local SSH daemon on `127.0.0.1:22`.

- `charlie`: remote `127.0.0.1:2222` -> local `127.0.0.1:22` through the Darwin launchd user agent.
- `axiom`: remote `127.0.0.1:2223` -> local `127.0.0.1:22` through the NixOS systemd service; `axiom` uses persistent `sshd.service` rather than OpenSSH socket activation so the local tunnel target is daemon-backed.

Do not reuse an existing remote port while its host tunnel remains active, and do not relax the remote bind address away from `127.0.0.1` without a new security review.
