{ config, lib, pkgs, ... }:

{
  imports = [
    ./.
    ./rofi.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      lightdm
      bspwm
      dunst
      libnotify
      (polybar.override {
        pulseSupport = true;
        nlSupport = true;
      })

      xst  # st + nice-to-have extensions
      (writeScriptBin "st-scratch" ''
        #!${stdenv.shell}
        SCRID=st-scratch
        focused=$(xdotool getactivewindow)
        scratch=$(xdotool search --onlyvisible --classname $SCRID)
        if [[ -n $scratch ]]; then
            if [[ $focused == $scratch ]]; then
                xdotool windowkill $scratch
            else
                xdotool windowactivate $scratch
            fi
        else
            xst -t $SCRID -n $SCRID -c $SCRID \
              -f "$(xrdb -query | grep 'st-scratch\.font' | cut -f2)" \
              -g 100x26 \
              -e $SHELL
        fi
      '')
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
