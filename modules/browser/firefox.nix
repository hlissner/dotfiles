# modules/browser/firefox.nix --- https://www.mozilla.org/en-US/firefox
#
# Oh firefox, gateway to the interwebs, devourer of ram. Give onto me your
# infinite knowledge and shelter me from ads.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    firefox-bin (pkgs.writeScriptBin "firefox-private" ''
      #! ${pkgs.bash}/bin/bash
      firefox --private-window "$@"
    '')
    (makeDesktopItem {
      name = "firefox-private";
      desktopName = "Firefox (Private)";
      genericName = "Open a private Firefox window";
      icon = "firefox";
      exec = "${firefox-bin}/bin/firefox --private-window";
      categories = "Network";
    })
  ];

  my.env.BROWSER = "firefox";
  my.env.XDG_DESKTOP_DIR = "$HOME"; # prevent firefox creating ~/Desktop
}
