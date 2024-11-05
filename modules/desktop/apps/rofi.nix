{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
let inherit (hey.lib.pkgs) mkWrapper mkLauncherEntry;
    cfg = config.modules.desktop.apps.rofi;

    rofiPkg = if config.modules.desktop.type == "wayland"
              then pkgs.rofi-wayland-unwrapped
              else pkgs.rofi-unwrapped;
    rofiFBPkg = pkgs.rofi-file-browser.override { rofi = rofiPkg; };
    rofiCalcPkg = pkgs.rofi-calc.override { rofi-unwrapped = rofiPkg; };
    rofiBlocksPkg = hey.packages.rofi-blocks.override { rofi-unwrapped = rofiPkg; };
in {
  options.modules.desktop.apps.rofi = with hey.lib.options; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.configFile."rofi" = {
        source = "${hey.configDir}/rofi";
        recursive = true;
      };

      programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

      environment.variables.ROFI_PLUGIN_PATH = [
        "$XDG_CONFIG_HOME/rofi/plugins"  # for local development
        "${rofiBlocksPkg}/lib/rofi"
        "${rofiFBPkg}/lib/rofi"
        "${rofiCalcPkg}/lib/rofi"
      ];

      user.packages = with pkgs; [
        rofiPkg
        (rofimoji.override { rofi = rofiPkg; })
        (mkLauncherEntry "Calculator" {
          icon = "calc";
          exec = "hey @rofi calcmenu";
          categories = [ "Development" ];
        })
        (mkLauncherEntry "Open Bookmark ->" {
          description = "In ${config.modules.desktop.browsers.default}";
          icon = "bookmark-new-symbolic";
          exec = "hey @rofi bookmarkmenu";
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
        (mkLauncherEntry "Manage audio devices ->" {
          icon = "audio-card";
          exec = "hey @rofi audiomenu";
        })
        (mkLauncherEntry "Manage Wireless Networks ->" {
          icon = "network-wireless";
          exec = "hey @rofi wifimenu";
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

    (mkIf config.modules.shell.vaultwarden.enable {
      user.packages = [
        (mkLauncherEntry "Password Manager" {
          icon = "changes-prevent";
          exec = "hey @rofi vaultmenu";
        })
        (mkLauncherEntry "Password Manager: resume from last time" {
          icon = "changes-prevent";
          exec = "hey @rofi vaultmenu -l";
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
