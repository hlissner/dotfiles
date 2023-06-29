## modules/desktop/bspwm.nix
#
# Sets up a BSPWM-based desktop environment.

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) configDir;
    cfg = config.modules.desktop.bspwm;
in {
  options.modules.desktop.bspwm = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.theme.onReload.bspwm.text = ''
      bspc wm -r
      $XDG_CONFIG_HOME/bspwm/bspwmrc
    '';

    modules.services.dunst.enable = true;

    environment.systemPackages = with pkgs; [
      lightdm
      libnotify
      (polybar.override {
        pulseSupport = true;
        nlSupport = true;
      })
    ];

    services = {
      picom.enable = true;
      redshift.enable = true;
      xserver = {
        enable = true;
        displayManager = {
          defaultSession = "none+bspwm";
          lightdm.enable = true;
          lightdm.greeters.mini.enable = true;
        };
        windowManager.bspwm.enable = true;
      };
    };

    # link recursively so other modules can link files in their folders
    home.configFile = {
      "sxhkd" = {
        source = "${configDir}/sxhkd";
        recursive = true;
      };
      "bspwm" = {
        source = "${configDir}/bspwm";
        recursive = true;
      };
    };

    env.PATH = [ "$XDG_CONFIG_HOME/bspwm/bin" ];
  };
}
