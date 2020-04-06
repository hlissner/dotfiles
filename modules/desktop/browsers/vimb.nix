# NOTE pkgs.vimb is unmaintained and broken on nixos. This module doesn't work,
# and only exists for posterity. Don't use it!

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.browsers.vimb = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.vimb.enable {
    my.packages = with pkgs; [
      vimb
      tabbed
      (makeDesktopItem {
        name = "vimb-private";
        desktopName = "Vimb (Private)";
        genericName = "Open an incognito Vimb window";
        icon = "vim";
        exec = "${firefox-bin}/bin/vimb --incognito";
        categories = "Network";
      })
    ];
  };
}
