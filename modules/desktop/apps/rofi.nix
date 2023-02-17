{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) binDir configDir;
    cfg = config.modules.desktop.apps.rofi;
in {
  options.modules.desktop.apps.rofi = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (writeShellScriptBin "rofi" ''
        exec ${rofi}/bin/rofi -terminal xst -m -1 "$@"
      '')

      # Shortcuts for bin/rofi/appmenu
      (makeDesktopItem {
        name = "rofi-browsermenu";
        desktopName = "Open Bookmark in Browser";
        icon = "bookmark-new-symbolic";
        exec = "${binDir}/rofi/browsermenu";
      })
      (makeDesktopItem {
        name = "rofi-browsermenu-history";
        desktopName = "Open Browser History";
        icon = "accessories-clock";
        exec = "${binDir}/rofi/browsermenu history";
      })
      (makeDesktopItem {
        name = "rofi-filemenu";
        desktopName = "Open Directory in Terminal";
        icon = "folder";
        exec = "${binDir}/rofi/filemenu";
      })
      (makeDesktopItem {
        name = "rofi-filemenu-scratch";
        desktopName = "Open Directory in Scratch Terminal";
        icon = "folder";
        exec = "${binDir}/rofi/filemenu -x";
      })
      (makeDesktopItem {
        name = "rofi-mojimenu";
        desktopName = "Insert Emoji/Unicode";
        icon = "accessories-character-map";
        exec = "${binDir}/rofi/mojimenu";
      })
      (makeDesktopItem {
        name = "rofi-powermenu";
        desktopName = "Power Control";
        icon = "system-shutdown";
        exec = "${binDir}/rofi/powermenu";
      })
      (makeDesktopItem {
        name = "lock-display";
        desktopName = "Lock screen";
        icon = "system-lock-screen";
        exec = "${binDir}/zzz";
      })
    ] ++ (if config.modules.shell.vaultwarden.enable then [
      (makeDesktopItem {
        name = "rofi-bwmenu";
        desktopName = "Insert password";
        icon = "changes-prevent";
        exec = "${binDir}/rofi/bwmenu";
      })
    ] else []);
  };
}
