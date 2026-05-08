# Decisions

## Linux Workstation Desktop Baseline

Current Linux workstation desktop direction is Hyprland + UWSM + DMS/Quickshell, with Zen as the browser baseline, mpv as the scoped media player, Vesktop/Discord as the scoped chat app, Steam Gamescope/Gamemode/Umu tuning, NetworkManager+iwd+resolved for workstation Wi-Fi, and BlueZ/Blueman reliability settings.

Old X11/bspwm/sxhkd/Polybar/Dunst/Waybar/legacy-idle/browser/media/Spotify compatibility is not preserved unless a future task explicitly reopens that scope.

Hyprland display-manager wiring should use the evaluated UWSM session entry `hyprland-uwsm.desktop`; `hyprland.desktop` is not present when Hyprland is exposed through the NixOS UWSM session package.

When NetworkManager uses iwd as the Wi-Fi backend, NetworkManager owns DHCP/routes. iwd's built-in network configuration should stay disabled, and workstation wired DHCP/autoconnect should be modeled through NetworkManager profiles rather than legacy `dhcpcd`.

## Darwin Boundary

Darwin remains a shared shell/dev/editor/XDG target. Linux desktop/system concerns such as Hyprland, DMS/Quickshell, Steam, NetworkManager/iwd, BlueZ/Blueman, portals, and display-manager wiring must stay out of Darwin imports unless a future Darwin-specific task changes the contract.
