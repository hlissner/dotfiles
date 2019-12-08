{ config, lib, pkgs, ... }:

{
  environment = {
    sessionVariables = {
      BROWSER = "firefox";
      XDG_DESKTOP_DIR = "$HOME"; # prevent firefox creating ~/Desktop
    };

    systemPackages = with pkgs; [
      firefox-bin
      (pkgs.writeScriptBin "firefox-private" ''
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
  };
}
