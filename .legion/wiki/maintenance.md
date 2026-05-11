# Maintenance

## Terminal Follow-Up

- Foot terminal notification behavior was disabled by removing unsupported `[main].notify` from the global config. If terminal notification behavior is still desired, restore it only through a Foot 1.25-supported option or an explicit external wrapper design validated with `foot --check-config`.

## Caelestia Shell Follow-Up

- Live Axiom validation remains required inside the actual Hyprland session: start or restart `caelestia-shell.service`, confirm the shell renders, and exercise launcher, sidebar/session/lock, notification/tray, OSD/media/brightness, screenshot/recording, wallpaper, default apps, polkit prompts, NetworkManager, Bluetooth, and power-profile paths.
- If Caelestia global shortcuts or CLI commands differ from the initial static mapping, update the Nix-generated Hyprland keybinds rather than restoring legacy end4 IPC or fuzzel assumptions.
- Revisit local `caelestia/shell.json` only for host policy that must be repository-owned. Avoid copying exhaustive upstream defaults unless a future task proves a stable need.
- After deploying the Caelestia wallpaper Qt theme fix and README alignment, restart Hyprland, confirm `path.txt` points at `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` unless another wallpaper was manually selected, confirm Caelestia logs no longer show the Qt allocation rejection, and verify `qtengine` does not reintroduce launcher color-block icon rendering.
- After deploying `axiom-desktop-polish-followup`, confirm the live Axiom session exercises `Super+Space`, sidebar/session, media, brightness, and screenshot keybinds through the CLI IPC route. If Super-key tap-to-launch is still desired, open a scoped follow-up for safe press/release behavior instead of restoring top-level `catchall`.
- After deploying `axiom-input-caelestia-config-hotfix`, restart `caelestia-shell.service`, confirm `~/.config/caelestia/shell.json` is a writable regular file, exercise `SUPER+Space`, `SUPER+Return`, and workspace bindings, and confirm the keyboard layout `Unknown` toast no longer appears by default. If `hyprctl -j devices` still reports an unknown active keymap, open a separate runtime/upstream input task instead of expanding the config hotfix.
- After deploying `axiom-keybinding-help-modal`, press `SUPER+/` in the real Axiom Hyprland session and confirm the themed shortcut reference modal opens. When generated keybinds change, update the repository-generated help text in the same task.

## Axiom Steam / opencode Follow-Up

- After deploying `axiom-desktop-polish-followup`, confirm Steam renders crisply on the 4K fractional-scale monitor and that games still choose expected render resolutions. If only individual games remain blurry, split a Steam game/runtime task with logs instead of broadening the desktop integration fix.
- In a fresh Axiom interactive shell and desktop-launched terminal, confirm `command -v opencode` resolves to `$HOME/.opencode/bin/opencode`.

## Axiom Input Follow-Up

- After deploying `axiom-fcitx5-shell-theme-alignment`, restart Fcitx5 or the graphical session and confirm the candidate UI visually uses the pink Catppuccin accent.

## Axiom Remote Access Follow-Up

- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME in Cloudflare DNS/Zero Trust. The active axiom opencode hostname is `opencode-axiom.0xc1.space`.
- Before using `opencode-axiom.0xc1.space`, create or verify the Cloudflare Access application, allow policy, and MFA requirement.
- After deploying the SSH/opencode/cloudflared fix, run `ssh azar`, `systemctl status autossh-reverse-ssh` on `azar`, and `systemctl status opencode-server cloudflared` on `axiom`.

## Cloudflare Credentials Follow-Up

- Rotate the Cloudflare API token stored in `hosts/charlie/secrets/cloudflare-api-token.age`, because the pre-existing token appeared in earlier tool output before being moved into age management.
