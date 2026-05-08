# Upstream Exploration

## Isabel Reference

- Repository: `/tmp/opencode/isabelroses-dotfiles.IafITY`
- Commit: `cf42f00`
- Zen status: no Zen module or package was found; browser productization is Chromium-centered.

Useful concepts:

- Hyprland productization in `home/isabel/gui/hyprland.nix`: declarative monitor/workspace mapping, curated app keybindings, sharing indicator window rules, network/Bluetooth window rules, and polished visual defaults.
- Quickshell enablement in `home/isabel/gui/quickshell.nix`: systemd-managed Quickshell with Qt/Kirigami/adwaita wrapper dependencies, but no reusable full shell UI was found in this snapshot.
- Browser concepts in `home/isabel/gui/chromium.nix`: Wayland/Ozone flags, Widevine, GPU flags, runtime cache, ff2mpv native messaging, and extension curation. These should be translated to Zen concepts rather than copied as Chromium baseline.
- Discord configuration in `home/isabel/gui/discord.nix` and `modules/home/programs/discord.nix`: OpenAsar/Moonlight setup, free screen share, native fixes, VAAPI ignore driver checks, and tracking/error-reporting disablement.
- mpv configuration in `home/isabel/gui/media/watching.nix`: `gpu-next`, Vulkan, `hwdec=auto-copy`, `gpu-hq`, SponsorBlock, modernz, thumbfast, MPRIS, ff2mpv, image-viewer and MIME integration.
- Portals in `modules/nixos/system/xdg-portals.nix`: system-owned portals, GTK fallback, WLR chooser via slurp, and Home Manager portal disabled. The new design should make the Hyprland portal explicit.
- Bluetooth in `modules/nixos/hardware/bluetooth.nix`: BlueZ enabled, SAP disabled, `JustWorksRepairing=always`, `MultiProfile=multiple`, `btusb`, and Blueman without applet.
- Network in `modules/nixos/networking/*.nix`: NetworkManager + iwd + resolved, scan MAC randomization, wait-online disabled, nm-connection-editor available without relying on an applet.

Avoid direct copy:

- Do not import the `garden` framework wholesale.
- Do not copy all Discord/Moonlight extensions blindly.
- Do not assume Isabel's Quickshell snapshot contains reusable shell UI.
- Do not rely on implicit portal backend ownership.

## hlissner Reference

- Repository: `/tmp/opencode/hlissner-dotfiles.ZqBHWc`
- Commit: `1b4383a`

Useful concepts:

- Architecture cleanup: removed X11/bspwm/sxhkd, Waybar, Dunst, Swayidle, Hypridle, old theme layers, old browser modules, Spotify/ncmpcpp, and many unused workstation/server modules.
- Hyprland in `modules/desktop/hyprland.nix`: `withUWSM = true`, `systemd.setPath.enable = true`, greetd launching `uwsm start -eD Hyprland hyprland.desktop`, DMS shell enablement, Quickshell package wiring, and Matugen template generation.
- Hyprland config in `config/hypr/hyprland.conf`: DMS notification toggle, Steam game rules, fullscreen idle inhibition, special workspaces, screenshot/screencast modal keys, and DMS audio integration.
- Steam in `modules/desktop/apps/steam.nix`: Steam remote play, `gamescopeSession.enable`, Gamemode hooks, Umu launcher, Mangohud, fake HOME wrapper, NTFS `compatdata` workaround, and `DefaultLimitNOFILE` tuning.
- Workstation in `modules/profiles/role/workstation.nix`: `sched_cfs_bandwidth_slice_us`, `tcp_fin_timeout`, `split_lock_mitigate`, `vm.max_map_count`, and `fs.inotify.max_user_watches`.
- Bluetooth in `modules/profiles/hardware/bluetooth.nix`: `ControllerMode=bredr`, `ReconnectAttempts=0`, and rfkill reset on resume.

Needs adaptation:

- hlissner removed Darwin entirely; this task must keep Darwin outputs and platform boundaries.
- DMS/Matugen depends on hlissner's `hey.info` metadata path and must be adapted.
- Isabel's NetworkManager+iwd path is more suitable for productized desktop UX than hlissner's older networkd Wi-Fi pattern.
