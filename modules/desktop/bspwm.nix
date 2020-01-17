{ config, lib, pkgs, ... }:

{
  imports = [
    # My launcher
    ./apps/rofi.nix

    # I often need a thumbnail browser to show off, peruse or organize photos,
    # design work, or digital art.
    ./apps/thunar.nix

    ./apps/redshift.nix
  ];

  environment.systemPackages = with pkgs; [
    lightdm
    bspwm
    dunst
    libnotify
    (polybar.override {
      pulseSupport = true;
      nlSupport = true;
    })
  ];

  services = {
    xserver = {
      enable = true;
      desktopManager.xterm.enable = false;
      windowManager.bspwm.enable = true;
      displayManager.lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = config.my.username;
        };
      };
    };
    compton.enable = true;
  };

  # For polybar
  my = {
    env.PATH = [ <config/bspwm/bin> ];
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
