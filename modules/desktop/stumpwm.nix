{ config, lib, pkgs, ... }:

{
  imports = [
    ./common.nix
  ];

  environment.systemPackages = with pkgs; [
    lightdm
    dunst
    libnotify
  ];

  # unstable.services.picom.enable = true;
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
  my.home.xdg.configFile."stumpwm" = {
    source = <config/stumpwm>;
    recursive = true;
  };
}
