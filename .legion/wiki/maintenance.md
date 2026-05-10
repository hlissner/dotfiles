# Maintenance

## Terminal Follow-Up

- Foot terminal notification behavior was disabled by removing unsupported `[main].notify` from the global config. If terminal notification behavior is still desired, restore it only through a Foot 1.25-supported option or an explicit external wrapper design validated with `foot --check-config`.

## Caelestia Shell Follow-Up

- Live Axiom validation remains required inside the actual Hyprland session: start or restart `caelestia-shell.service`, confirm the shell renders, and exercise launcher, sidebar/session/lock, notification/tray, OSD/media/brightness, screenshot/recording, wallpaper, default apps, polkit prompts, NetworkManager, Bluetooth, and power-profile paths.
- If Caelestia global shortcuts or CLI commands differ from the initial static mapping, update the Nix-generated Hyprland keybinds rather than restoring legacy end4 IPC or fuzzel assumptions.
- Revisit local `caelestia/shell.json` only for host policy that must be repository-owned. Avoid copying exhaustive upstream defaults unless a future task proves a stable need.
- After deploying the Caelestia wallpaper Qt theme fix, restart Hyprland, confirm `path.txt` points at `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` unless another wallpaper was manually selected, confirm Caelestia logs no longer show the Qt allocation rejection, and verify launcher icons no longer render as color blocks.
