{ config, lib, pkgs, ... }:

{
  environment = {
    sessionVariables = {
      BROWSER = "firefox";
      XDG_DESKTOP_DIR = "$HOME"; # prevent firefox creating ~/Desktop
    };

    systemPackages = with pkgs; [
      firefox
      (pkgs.writeScriptBin "firefox-private" ''
        #! ${pkgs.bash}/bin/bash
        firefox --private-window "$@"
      '')
    ];
  };
}
