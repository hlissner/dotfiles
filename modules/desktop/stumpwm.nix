{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.stumpwm;
    configDir = config.dotfiles.configDir;
in {
  options.modules.desktop.stumpwm = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lightdm
      dunst
      libnotify
    ];

    # master.services.picom.enable = true;
    services = {
      redshift.enable = true;
      xserver = {
        enable = true;
        windowManager.default = "stumpwm";
        windowManager.stumpwm.enable = true;
        displayManager.lightdm.enable = true;
        displayManager.lightdm.greeters.mini.enable = true;
      };
    };

    # link recursively so other modules can link files in their folders
    home.configFile."stumpwm" = {
      source = "${configDir}/stumpwm";
      recursive = true;
    };
  };
}
