## Summary

- Manage Fcitx5 Catppuccin Mocha Mauve in both system and user-level `classicui.conf` so stale user UI config no longer hides the theme.
- Add reusable `modules.desktop.apps.clash-verge` with `pkgs.clash-verge-rev` as the default package.
- Enable Clash Verge only on `axiom`.

## Verification

- `nix eval --impure '.#nixosConfigurations.axiom.config.home.configFile."fcitx5/conf/classicui.conf".text'`
- `nix eval --impure '.#nixosConfigurations.axiom.config.home.configFile."fcitx5/conf/classicui.conf".force'`
- `nix eval --impure '.#nixosConfigurations.axiom.config.environment.etc."xdg/fcitx5/conf/classicui.conf".text'`
- `nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.axiom.config.modules.desktop.apps."clash-verge".enable'`
- `nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in builtins.elem (cfg.modules.desktop.apps."clash-verge".package.pname or cfg.modules.desktop.apps."clash-verge".package.name) (map (p: p.pname or p.name) cfg.users.users.c1.packages)'`
- `nix eval --impure '.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath'`

## Notes

- The Fcitx change force-manages only `~/.config/fcitx5/conf/classicui.conf`; it does not touch Rime or dictionary paths.
- Clash Verge runtime profiles/subscriptions remain user-managed and out of scope.
