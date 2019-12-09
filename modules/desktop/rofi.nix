{ config, lib, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (writeScriptBin "rofi" ''
        #!${stdenv.shell}
        exec ${rofi}/bin/rofi -terminal xst -m -1 "$@"
        '')
      rofi

      # Fake rofi dmenu entries
      (makeDesktopItem {
        name = "rofi-browsermenu";
        desktopName = "Open Bookmark in Firefox";
        icon = "firefox";
        exec = "${<config/rofi>}/bin/rofi-browsermenu";
        categories = "Network;Utility";
      })
      (makeDesktopItem {
        name = "rofi-filemenu";
        desktopName = "Open Directory in Terminal";
        icon = "folder";
        exec = "${<config/rofi>}/bin/rofi-filemenu";
        categories = "System;Utility";
      })
      (makeDesktopItem {
        name = "rofi-filemenu-scratch";
        desktopName = "Open Directory in Scratch Terminal";
        icon = "folder";
        exec = "${<config/rofi>}/bin/rofi-filemenu -x";
        categories = "System;Utility";
      })

    ];
  };

  home-manager.users.hlissner.xdg.configFile = {
    # link recursively so other modules can link files in its folder
    "rofi" = {
      source = <config/rofi>;
      recursive = true;
    };
  };
}
