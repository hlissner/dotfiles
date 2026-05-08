# Test Report

## Result
PASS

## Commands

```sh
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:/home/c1/dotfiles/.worktrees/axiom-fcitx5-wechat-wallpaper"; cfg = flake.nixosConfigurations.axiom.config; in { enable = cfg.i18n.inputMethod.enable; type = cfg.i18n.inputMethod.type; addons = map (p: p.pname or p.name) cfg.i18n.inputMethod.fcitx5.addons; theme = cfg.i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme; wallpaper = cfg.modules.theme.wallpapers."*"; }'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:/home/c1/dotfiles/.worktrees/axiom-fcitx5-wechat-wallpaper"; cfg = flake.nixosConfigurations.atlas.config; in { enable = cfg.i18n.inputMethod.enable; type = cfg.i18n.inputMethod.type; addons = map (p: p.pname or p.name) cfg.i18n.inputMethod.fcitx5.addons; }'
nix eval --impure --raw '.#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme'
nix eval --impure --raw '.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath'
nix eval --impure --json --expr 'let flake = builtins.getFlake "git+file:/home/c1/dotfiles/.worktrees/axiom-fcitx5-wechat-wallpaper"; c = flake.nixosConfigurations.axiom.config; in { quickshellWantedBy = c.systemd.user.services.quickshell.wantedBy; quickshellAfter = c.systemd.user.services.quickshell.after; quickshellPartOf = c.systemd.user.services.quickshell.partOf; wallpaper = c.modules.theme.wallpapers."*"; }'
nix eval --impure --raw --expr 'let flake = builtins.getFlake "git+file:/home/c1/dotfiles/.worktrees/axiom-fcitx5-wechat-wallpaper"; in flake.nixosConfigurations.axiom.config.hey.hooks.startup."10-wallpaper"'
```

## Evidence

- `axiom` input method evaluates with `enable = true` and `type = "fcitx5"`.
- `axiom` Fcitx5 addons evaluate to `fcitx5-gtk`, `fcitx5-qt6`, `fcitx5-rime`, `fcitx5-chinese-addons`, and `catppuccin-fcitx5`.
- `axiom` Fcitx5 classic UI theme evaluates to `catppuccin-mocha-mauve`.
- `axiom` wallpaper evaluates to `{ mode = "stretch"; path = "/home/c1/the-great-sage.jpg"; }`.
- `quickshell.service` evaluates with `wantedBy`, `after`, and `partOf` all scoped to `hyprland-session.target`, avoiding early startup from `graphical-session.target` before Hyprland environment import.
- The generated wallpaper startup hook now runs `pkill -x swaybg || true` before launching `swaybg -m stretch`, so reload replaces stale centered background instances.
- Existing `atlas` `fcitx5-rime.enable` compatibility evaluates to Fcitx5 enabled with `fcitx5-gtk`, `fcitx5-qt6`, `fcitx5-rime`, and `catppuccin-fcitx5`.
- `axiom` system toplevel derivation evaluates to `/nix/store/vrczv1m3bgxvl8a2jbc67zls25fsf3f9-nixos-system-axiom-25.11.20260203.e576e3c.drv` after the follow-up runtime fixes.

## Notes

- Initial review caught that the new module was untracked, which made git-flake evaluation ignore it. The new module and task docs were staged with `git add` so `. #` / `git+file:` evaluation sees the same source shape that a commit/PR would carry.
- Evaluation emitted pre-existing repository warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; none were introduced by this change.
- Runtime typing inside WeChat and Quickshell button clicks still require rebuilding/switching `axiom` and testing in the actual compositor session.
