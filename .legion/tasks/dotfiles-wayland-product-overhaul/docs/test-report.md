# Test Report: Wayland Product Overhaul

## Commands Run

- `nix flake lock` — passed; removed the root `spicetify-nix` lock nodes after the input was deleted.
- `nix flake lock --update-input dotfiles` from `hosts/aliyun-acorn/image` — passed; refreshed the nested image lock and removed stale `dotfiles/spicetify-nix` nodes.
- `git add -N modules/desktop/quickshell.nix modules/desktop/apps/discord.nix modules/desktop/browsers/zen.nix` — required before validation because Git flakes do not reliably evaluate untracked new module files.
- `nix flake show --impure --all-systems` — passed; Linux/Darwin apps, devShells, packages, and NixOS configurations enumerate.
- `nix eval --impure .#nixosConfigurations.{ramen,harusame,udon,azar,atlas,axiom}.config.system.name` — passed for all six retained hosts.
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` — passed after fixing build-time issues found by this command.
- Key option checks — passed: `ramen` default browser command is `"zen-beta"`; `BROWSER = "zen-beta"`; Zen package is `"zen-beta-1.19.11b"`; HTTPS MIME default is `"zen-beta.desktop"`; Zen WM class is `"zen-beta"`; generated Hyprland rules include `zen-beta`; Hyprland `withUWSM = true`; Quickshell/DMS enablement is `true`; DMS service starts `${dms}/bin/dms run`; portal `xdgOpenUsePortal = true`; NetworkManager is enabled on `ramen`; Bluetooth `JustWorksRepairing = "always"`; `udon` Steam Gamescope and Gamemode are enabled; mpv and Vesktop config files generate.
- Zen-enabled host browser defaults — passed: `ramen`, `harusame`, `udon`, `azar`, `atlas`, and `axiom` all evaluate `modules.desktop.browsers.default` to `"zen-beta"`.
- Legacy searches — passed: no `config/bspwm`, `config/sxhkd`, or `config/waybar` files; no active Nix matches for `bspwm|sxhkd|polybar|dunst|waybar|swayidle|hypridle|librewolf|brave|google-chrome|microsoft-edge|spicetify|spotify`; no Hyprland config matches for `makoctl|swayidle|hypridle|bspwm|waybar|polybar|librewolf|spicetify|spotify`; no `spicetify|spotify` matches in flake locks; no old autumnal theme config paths.
- Darwin boundary search in `darwin/*.nix` for `hyprland|quickshell|dms|steam|gamescope|gamemode|NetworkManager|networkmanager|iwd|bluetooth|blueman` — passed with no matches.

## Validation-Discovered Fixes

- Initial DMS option checks failed because new module files were untracked and therefore invisible to the Git flake evaluator. Marking new modules intent-to-add made Nix evaluate them.
- `nix build --impure --dry-run .#nixosConfigurations.ramen.config.system.build.toplevel` initially failed on the removed `pkgs.unstable.xwaylandvideobridge` alias. The Discord module now relies on Vesktop plus portal-backed screen sharing instead of the removed package.
- The same dry-run then failed because `modules.desktop.quickshell.enable` was counted as a second desktop environment. The desktop assertion now counts only actual desktop environment modules.
- Readiness review found that Zen integration used `zen`/`zen.desktop` while the selected package exposes `zen-beta`/`zen-beta.desktop` and `StartupWMClass=zen-beta`. The browser module and Hyprland rule now use package-accurate defaults.
- Re-review found remaining host-level `default = "zen"` overrides on `azar`, `atlas`, and `axiom`; those overrides were removed and all six Zen-enabled hosts now evaluate to `"zen-beta"`.
- `axiom` dry-run found additional build-time issues that plain evaluation missed: NetworkManager settings needed quoted dotted INI keys, `nm-connection-editor` is not a package attribute and is provided by `networkmanagerapplet`, `rofi-wayland-unwrapped` was removed in favor of `rofi-unwrapped`, and Steam's `vm.max_map_count` tuning needed `mkForce` to override the NixOS default.

## Blocked/Deferred

- `nix build --impure --dry-run .#nixosConfigurations.ramen.config.system.build.toplevel` reaches system build evaluation and is blocked only by the pre-existing agenix assertion: no host key at `/etc/ssh/host_ed25519`. `axiom` toplevel dry-run passes locally.
- Concrete Darwin build/runtime validation remains deferred to a Darwin machine per contract.
- Manual hardware/session checks for Hyprland startup, DMS UI, portals/screenshare, Wi-Fi roaming, Bluetooth pairing, Steam launch, and mpv playback are deferred.
