{ config, lib, pkgs, ... }:

{
  my = {
    env.PATH = [ <my/config/rofi/bin> ];
    # link recursively so other modules can link files in its folder
    home.xdg.configFile."rofi" = {
      source = <my/config/rofi>;
      recursive = true;
    };

    packages = with pkgs; [
      (writeScriptBin "rofi" ''
        #!${stdenv.shell}
        exec ${rofi}/bin/rofi -terminal xst -m -1 "$@"
        '')

      # Fake rofi dmenu entries
      (makeDesktopItem {
        name = "rofi-browsermenu";
        desktopName = "Open Bookmark in Firefox";
        icon = "bookmark-new-symbolic";
        exec = "${<my/config/rofi>}/bin/rofi-browsermenu";
      })
      (makeDesktopItem {
        name = "rofi-filemenu";
        desktopName = "Open Directory in Terminal";
        icon = "folder";
        exec = "${<my/config/rofi>}/bin/rofi-filemenu";
      })
      (makeDesktopItem {
        name = "rofi-filemenu-scratch";
        desktopName = "Open Directory in Scratch Terminal";
        icon = "folder";
        exec = "${<my/config/rofi>}/bin/rofi-filemenu -x";
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
}
