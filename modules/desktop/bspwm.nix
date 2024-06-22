## modules/desktop/bspwm.nix
#
# Sets up a BSPWM-based desktop environment.
#
# TODO: Replace maim/slop with flameshot
# TODO: Need hey .osd analog
# TODO: Need hey.info support
# TODO: Need hey.hooks support
# TODO: Need hey hook startup analog
# TODO: Need hey hook reload analog
# TODO: Need monitors options

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.bspwm;
in {
  options.modules.desktop.bspwm = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.desktop.type = "x11";

    modules.services.dunst.enable = true;

    environment.systemPackages = with pkgs; [
      lightdm
      (polybar.override {
        pulseSupport = true;
        nlSupport = true;
      })
    ];

    services = {
      picom = {
        enable = true;
        package = pkgs.unstable.picom;
      };
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
        source = "${self.configDir}/sxhkd";
        recursive = true;
      };
      "bspwm" = {
        source = "${self.configDir}/bspwm";
        recursive = true;
      };
    };
  };
}
