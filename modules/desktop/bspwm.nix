{ config, lib, pkgs, ... }:

{
  imports = [
    ./.
    ./rofi.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      xst  # st + nice-to-have extensions

      lightdm
      bspwm
      dunst
      libnotify

      (polybar.override {
        pulseSupport = true;
        nlSupport = true;
      })
    ];
  };

  fonts.fonts = [ pkgs.siji ];

  programs.zsh.interactiveShellInit = "export TERM=xterm-256color";

  services = {
    xserver = {
      desktopManager.xterm.enable = false;
      displayManager.lightdm.enable = true;
      windowManager.bspwm.enable = true;
    };

    compton = {
      enable = true;
      backend = "glx";
      vSync = true;
      inactiveOpacity = "0.90";
      opacityRules = ["100:class_g = 'Firefox'"];
    };
  };

  home-manager.users.hlissner.xdg.configFile = {
    "sxhkd".source = <config/sxhkd>;

    # link recursively so other modules can link files in their folders
    "bspwm" = { source = <config/bspwm>; recursive = true; };
  };
}
