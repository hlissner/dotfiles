# modules/browser/qutebrowser.nix --- https://github.com/qutebrowser/qutebrowser
#
# Qutebrowser is cute because it's not enough of a browser to be handsome.
# Still, we can all tell he'll grow up to be one hell of a lady-killer.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.browsers.qutebrowser = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.qutebrowser.enable {
    my.packages = with pkgs; [
      qutebrowser
      (makeDesktopItem {
        name = "qutebrowser-private";
        desktopName = "Qutebrowser (Private)";
        genericName = "Open a private Qutebrowser window";
        icon = "qutebrowser";
        exec = "${qutebrowser}/bin/qutebrowser ':open -p'";
        categories = "Network";
      })
    ];
    my.home.xdg.configFile."qutebrowser" = {
      source = <config/qutebrowser>;
      recursive = true;
    };
  };
}
