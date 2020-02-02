{ config, lib, pkgs, ... }:

# let unstable = import <nixos-unstable> {};
# in
{
  imports = [
    ./.  # common settings
  ];

  environment.systemPackages = with pkgs; [
    lightdm
    dunst
    libnotify
  ];

  # unstable.services.picom.enable = true;
  services = {
    xserver = {
      windowManager.default = "stumpwm";
      windowManager.stumpwm.enable = true;
      displayManager.lightdm.enable = true;
      displayManager.lightdm.greeters.mini.enable = true;
    };
  };

  # link recursively so other modules can link files in their folders
  my.home.xdg.configFile."stumpwm" = {
    source = <config/stumpwm>;
    recursive = true;
  };
}
