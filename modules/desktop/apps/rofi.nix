{ self, lib, config, options, pkgs, ... }:

with builtins;
with lib;
let
  inherit (self) binDir;
  cfg = config.modules.desktop.apps.rofi;
in {
  options.modules.desktop.apps.rofi = with self.lib.options; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; with self.lib.pkgs; [
      (mkWrapper rofi ''
        wrapProgram "$out/bin/rofi" --add-flags "-terminal xst -m -1"
      '')

      # Shortcuts for bin/rofi/*menu scripts
      (mkLauncherEntry "Open Bookmark in Browser" {
        icon = "bookmark-new-symbolic";
        exec = "${binDir}/rofi/browsermenu";
      })
      (mkLauncherEntry "Open Browser History" {
        icon = "accessories-clock";
        exec = "${binDir}/rofi/browsermenu history";
      })
      (mkLauncherEntry "Open Directory in Terminal" {
        icon = "folder";
        exec = "${binDir}/rofi/filemenu";
      })
      (mkLauncherEntry "Open Directory in Scratch Terminal" {
        icon = "folder";
        exec = "${binDir}/rofi/filemenu -x";
      })
      (mkLauncherEntry "Insert Emoji/Unicode" {
        icon = "accessories-character-map";
        exec = "${binDir}/rofi/mojimenu";
      })
      (mkLauncherEntry "Power Control" {
        icon = "system-shutdown";
        exec = "${binDir}/rofi/powermenu";
      })
      (mkLauncherEntry "Lock displays" {
        icon = "system-lock-screen";
        exec = "xset dpms force off";
      })
    ] ++ (if config.modules.shell.vaultwarden.enable then [
      (mkLauncherEntry "Insert password" {
        icon = "changes-prevent";
        exec = "${binDir}/rofi/bwmenu";
      })
    ] else []);
  };
}
