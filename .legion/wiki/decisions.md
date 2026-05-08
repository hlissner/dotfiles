# Decisions

## Linux Workstation Desktop Baseline

Current Linux workstation desktop direction is Hyprland + UWSM + DMS/Quickshell, with Zen as the browser baseline, mpv as the scoped media player, Vesktop/Discord as the scoped chat app, Steam Gamescope/Gamemode/Umu tuning, NetworkManager+iwd+resolved for workstation Wi-Fi, and BlueZ/Blueman reliability settings.

Old X11/bspwm/sxhkd/Polybar/Dunst/Waybar/legacy-idle/browser/media/Spotify compatibility is not preserved unless a future task explicitly reopens that scope.

## Darwin Boundary

Darwin remains a shared shell/dev/editor/XDG target. Linux desktop/system concerns such as Hyprland, DMS/Quickshell, Steam, NetworkManager/iwd, BlueZ/Blueman, portals, and display-manager wiring must stay out of Darwin imports unless a future Darwin-specific task changes the contract.
