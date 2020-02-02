{ config, lib, pkgs, ... }:

{
  imports = [
    ./.  # common settings
  ];

  environment.systemPackages = with pkgs; [
    lightdm
    dunst
    libnotify
    (polybar.override {
      pulseSupport = true;
      nlSupport = true;
    })
  ];

  services = {
    compton.enable = true;
    xserver = {
      windowManager.default = "bspwm";
      windowManager.bspwm.enable = true;
      displayManager.lightdm.enable = true;
      displayManager.lightdm.greeters.mini.enable = true;
    };
  };

  my = {
    env.PATH = [ <bin/bspwm> ];
    home.xdg.configFile = {
      "sxhkd".source = <config/sxhkd>;
      # link recursively so other modules can link files in their folders
      "bspwm" = {
        source = <config/bspwm>;
        recursive = true;
      };
    };
  };
}
