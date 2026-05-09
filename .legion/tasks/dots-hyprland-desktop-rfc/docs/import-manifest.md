# Import Manifest: end4 dots-hyprland

## Source

- Upstream: `https://github.com/end-4/dots-hyprland`
- Commit: `bebf66da89cd2afa4738da47fb3a0a9fa5af7035`
- Required submodule: `dots/.config/quickshell/ii/modules/common/widgets/shapes` from `https://github.com/end-4/rounded-polygon-qmljs.git` at `e31ec4cb4ebf6a46b267f5c42eabf6874916fa16`
- Local clone used for import only: `.upstream/end4-dots-hyprland/`
- Upstream `setup` was not run.

## Copied Source Paths

- `dots/.config/quickshell/ii` -> `config/quickshell/ii`
  - Includes `shell.qml`, `GlobalStates.qml`, `settings.qml`, `welcome.qml`, `ReloadPopup.qml`, `killDialog.qml`, `.qmlformat.ini`, `assets/**`, `defaults/**`, `modules/**`, `panelFamilies/**`, `scripts/**`, `services/**`, and `translations/**`.
  - This is the required source for `quickshell --config ii` and `IllogicalImpulseFamily`.
- `dots/.config/quickshell/ii/modules/common/widgets/shapes` submodule -> `config/quickshell/ii/modules/common/widgets/shapes`
  - Required by `MaterialCookie.qml` and `MaterialShape.qml` for rounded polygon/material shape imports.
  - The submodule `.git` metadata was not copied.
- `dots/.config/matugen` -> `config/matugen`
  - Includes template sources for Quickshell material colors, Hyprland, Hyprlock, GTK, KDE wrapper output, terminal/wallpaper state, and fuzzel theme generation.
- `dots/.config/fuzzel/fuzzel.ini` -> `config/fuzzel/fuzzel.ini`
  - Imported for the end4 launcher fallback path used by Hyprland keybinds.
  - The generated `fuzzel_theme.ini` output was intentionally omitted.
- `dots/.config/hypr/hyprland.conf` -> `config/hypr/hyprland.conf`
- `dots/.config/hypr/hyprland/**` -> `config/hypr/hyprland/**`
  - Includes upstream env, variables, general, rules, keybinds, scripts, and shell override slots.
- `dots/.config/hypr/hypridle.conf` -> `config/hypr/hypridle.conf`
- `dots/.config/hypr/hyprlock.conf` -> `config/hypr/hyprlock.conf`
- `dots/.config/hypr/hyprlock/check-capslock.sh` -> `config/hypr/hyprlock/check-capslock.sh`
- `dots/.config/hypr/hyprlock/status.sh` -> `config/hypr/hyprlock/status.sh`

## Intentionally Omitted Upstream Paths

- `setup`: installer entrypoint that mutates the live home environment and package manager state.
- `sdata/**`: installer libraries, distro package scripts, dependency installers, update/uninstall commands, experimental merge/update commands, virtual monitor helpers, and upstream Home Manager examples. NixOS modules in this repository own those responsibilities.
- `dots-extra/**`: optional extras outside the accepted `ii` desktop runtime path.
- `dots/.config/chrome-flags.conf`, `code-flags.conf`, `darklyrc`, `dolphinrc`, `fish/**`, `fontconfig/**`, `foot/**`, `kde-material-you-colors/**`, `kdeglobals`, `kitty/**`, `konsolerc`, `Kvantum/**`, `mpv/**`, `starship.toml`, `thorium-flags.conf`, `wlogout/**`, `xdg-desktop-portal/**`, `zshrc.d/**`: adjacent application configs not required for `ii/shell.qml` loadability and already owned by this repository's NixOS modules or left for future scoped imports.
- `dots/.config/hypr/custom/*.conf`, `dots/.config/hypr/monitors.conf`, `dots/.config/hypr/workspaces.conf`: upstream mutable/custom placeholders. Axiom generates these through Nix instead.
- Generated color/runtime outputs from upstream, including `dots/.config/hypr/hyprland/colors.conf`, `dots/.config/hypr/hyprlock/colors.conf`, and `dots/.config/fuzzel/fuzzel_theme.ini`.
- API keys, credentials, live cache/state, local user config JSON, and generated wallpaper/color state. None were intentionally imported.

## Nix-Generated Override Paths

- `~/.config/quickshell/ii` links `config/quickshell/ii` and is the active Quickshell runtime config.
- `~/.config/matugen` links `config/matugen` for runtime theme generation templates.
- `~/.config/fuzzel` links `config/fuzzel` for fallback launcher configuration.
- `~/.config/hypr/monitors.conf` is generated from `modules.desktop.hyprland.monitors`.
- `~/.config/hypr/workspaces.conf` is generated from Axiom workspace defaults.
- `~/.config/hypr/custom/env.conf` is generated from NixOS session, default app, and `ILLOGICAL_IMPULSE_VIRTUAL_ENV` facts.
- `~/.config/hypr/custom/variables.conf` sets `$qsConfig = ii`, host default apps, and `$dontLoadDefaultExecs = 1` so NixOS owns session services while retaining upstream general/rules/keybind layers.
- `~/.config/hypr/custom/execs.conf` starts `hey hook startup` and restores video wallpaper only from XDG state if a generated restore script exists.
- `~/.config/hypr/custom/rules.conf`, `keybinds.conf`, and `general.conf` contain Axiom host placement, fallback keybinds, and module `extraConfig`.
- `~/.local/state/quickshell/user/generated/hypr/restore_video_wallpaper.sh` is the patched runtime restore-script location for video wallpapers; it is not committed.

## Local Integration Adjustments

- `modules/desktop/quickshell.nix` defaults `configName = "ii"` and links `quickshell/ii`, `matugen`, and `fuzzel`.
- The legacy `config/quickshell/axiom-shell` is documented as deprecated and is not the default runtime config.
- The old Axiom helper packages were removed from the active Quickshell path; `ii` uses upstream QML services and scripts.
- Axiom builds Quickshell `0.3.0` from upstream tag `v0.3.0` because imported `ii` uses `Quickshell.Services.Polkit`, which is absent from the pinned `0.2.1` package.
- A Nix-provided Python environment replaces upstream setup-created virtualenv assumptions for material color/image helper scripts.
- External KDE polkit agent startup is disabled by default because imported `ii` includes `Quickshell.Services.Polkit` UI.
- `config/hypr/hyprland.conf` treats generated color, monitor, and workspace files as no-error sources so the repository does not commit generated outputs.
