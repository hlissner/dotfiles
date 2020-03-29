# modules/browser/firefox.nix --- https://www.mozilla.org/en-US/firefox
#
# Oh firefox, gateway to the interwebs, devourer of ram. Give onto me your
# infinite knowledge and shelter me from ads.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.browsers.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.firefox.enable {
    my.packages = with pkgs; [
      firefox-bin
      (makeDesktopItem {
        name = "firefox-private";
        desktopName = "Firefox (Private)";
        genericName = "Open a private Firefox window";
        icon = "firefox";
        exec = "${firefox-bin}/bin/firefox --private-window";
        categories = "Network";
      })
    ];
    my.env.XDG_DESKTOP_DIR = "$HOME"; # (try to) prevent ~/Desktop
  };
}
