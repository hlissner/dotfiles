# test/nixos/modules/zellij.nix --- tests for modules/shell/zellij.nix
#
# zellij has no include/source directive, and -- worse -- it drops config nodes
# it doesn't recognise without erroring, so a misconfiguration here is invisible
# at runtime. The module's whole job is therefore one environment variable
# pointing at config/zellij/, plus making sure the generated theme lands where
# zellij will actually look for it.

{ evalConfig, lib, ... }:

with lib;
let
  zellij = evalConfig [{ modules.shell.zellij.enable = true; }];
  configDir = zellij.environment.variables.ZELLIJ_CONFIG_DIR;
in {
  # config.kdl, layouts/ and themes/ are all resolved relative to
  # ZELLIJ_CONFIG_DIR, so pointing it at the dotfiles (not $XDG_CONFIG_HOME,
  # where zellij would find nothing) is what keeps them editable without a
  # rebuild -- and themes/ is only searched beneath it, so the rendered theme
  # has to land there too rather than where tmux's colors.conf goes.
  testConfigDirIsTheDotfilesAndTheThemeLandsInIt =
    let t = zellij.modules.hyprland.theme.templates.zellij; in {
      expr = {
        dotfiles = hasSuffix "/config/zellij" configDir;
        theme = hasPrefix configDir t.output_path && hasSuffix "/themes/colors.kdl" t.output_path;
      };
      expected = { dotfiles = true; theme = true; };
    };
}
