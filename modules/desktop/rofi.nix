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
        icon = "bookmark-new-symbolic";
        exec = "${<config/rofi>}/bin/rofi-browsermenu";
      })
      (makeDesktopItem {
        name = "rofi-filemenu";
        desktopName = "Open Directory in Terminal";
        icon = "folder";
        exec = "${<config/rofi>}/bin/rofi-filemenu";
      })
      (makeDesktopItem {
        name = "rofi-filemenu-scratch";
        desktopName = "Open Directory in Scratch Terminal";
        icon = "folder";
        exec = "${<config/rofi>}/bin/rofi-filemenu -x";
      })

      (makeDesktopItem {
        name = "reboot";
        desktopName = "System: Reboot";
        icon = "system-reboot";
        exec = "systemctl reboot";
      })
      (makeDesktopItem {
        name = "shutdown";
        desktopName = "System: Shut Down";
        icon = "system-shutdown";
        exec = "systemctl shutdown";
      })
      (makeDesktopItem {
        name = "sleep";
        desktopName = "System: Sleep";
        icon = "system-suspend";
        exec = "systemctl suspend";
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
