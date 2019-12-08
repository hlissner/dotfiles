{ config, lib, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (writeScriptBin "rofi" ''
        #!${stdenv.shell}
        exec ${rofi}/bin/rofi -terminal xst -m -1 "$@"
        '')
      rofi

      (makeDesktopItem {
        name = "browsermenu";
        desktopName = "Open Bookmark in Firefox";
        icon = "firefox";
        exec = "/home/hlissner/.config/rofi/bin/browsermenu";
        categories = "Network";
      })
    ];

    # shellAliases = {};
  };

  home-manager.users.hlissner.xdg.configFile = {
    # link recursively so other modules can link files in its folder
    "rofi" = { source = <config/rofi>; recursive = true; };
    "zsh/rc.d/env.rofi.zsh".source = <config/rofi/env.zsh>;
  };
}
