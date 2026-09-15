{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
let inherit (hey.lib.pkgs) mkWrapper mkLauncherEntry;
    cfg = config.modules.apps.rofi;

    rofiPkg = pkgs.rofi-unwrapped;
    rofiFBPkg = pkgs.rofi-file-browser.override { rofi = rofiPkg; };
    rofiCalcPkg = pkgs.rofi-calc.override { rofi-unwrapped = rofiPkg; };
in {
  options.modules.apps.rofi = with hey.lib.options; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      modules.hyprland.matugen.templates.rofi = {
        input_path = "${hey.configDir}/rofi/colors.template.rasi";
        output_path = "${config.home.configDir}/rofi/themes/colors.rasi";
      };

      home.configFile."rofi" = {
        source = "${hey.configDir}/rofi";
        recursive = true;
      };

      programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

      environment.variables.ROFI_PLUGIN_PATH = [
        "$XDG_CONFIG_HOME/rofi/plugins"  # for local development
        "${rofiFBPkg}/lib/rofi"
        "${rofiCalcPkg}/lib/rofi"
      ];

      user.packages = with pkgs; [
        rofiPkg
        rofimoji
        (mkLauncherEntry "Calculator" {
          icon = "calc";
          exec = "hey @rofi calcmenu";
          categories = [ "Development" ];
        })
        (mkLauncherEntry "Open Bookmark ->" {
          description = "In ${config.modules.apps.browsers.default}";
          icon = "bookmark-new-symbolic";
          exec = "hey @rofi bookmarkmenu";
        })
        (mkLauncherEntry "Copy Icon ->" {
          icon = "icons";
          exec = "hey @rofi iconmenu";
        })
        (mkLauncherEntry "Open File ->" {
          icon = "folder";
          exec = ''hey @rofi filemenu -file-browser-dir "\$HOME"'';
        })
        (mkLauncherEntry "Open Directory in Terminal ->" {
          icon = "folder";
          exec = ''hey @rofi filemenu -file-browser-dir "\$HOME" -file-browser-depth 4 -file-browser-no-descend -file-browser-only-dirs -file-browser-cmd "hey .open-term -- cd"'';
        })
        (mkLauncherEntry "Emoji Selector ->" {
          icon = "face-smile";
          exec = "hey @rofi emojimenu";
        })
        (mkLauncherEntry "Power Menu ->" {
          icon = "system-shutdown";
          exec = "hey @rofi powermenu";
        })
      ];
    }

    (mkIf config.hardware.bluetooth.enable {
      user.packages = [
        (mkLauncherEntry "Manage Bluetooth Devices ->" {
          icon = "bluetooth";
          exec = "${pkgs.rofi-bluetooth}/bin/rofi-bluetooth";
        })
      ];
    })

    (mkIf config.services.udisks2.enable {
      user.packages = [
        (mkLauncherEntry "Mount/unmount Devices ->" {
          icon = "drive-harddisk";
          exec = "hey @rofi mountmenu";
        })
      ];
    })
  ]);
}
