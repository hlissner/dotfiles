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
      (makeDesktopItem {
        name = "xst";
        desktopName = "Suckless Terminal";
        genericName = "Default terminal";
        icon = "xterm";
        exec = "${xst}/bin/xst";
        categories = "Development;System;Utility";
      })
    ];
  };

  fonts.fonts = [ pkgs.siji ];

  programs.zsh.interactiveShellInit = "export TERM=xterm-256color";

  services = {
    xserver = {
      desktopManager.xterm.enable = false;
      windowManager.bspwm.enable = true;
      displayManager.lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = "hlissner";
        };
      };
    };

    compton = {
      enable = true;
      backend = "glx";
      vSync = true;
    };
  };

  home-manager.users.hlissner.xdg.configFile = {
    "sxhkd".source = <config/sxhkd>;

    # link recursively so other modules can link files in their folders
    "bspwm" = { source = <config/bspwm>; recursive = true; };
  };
}
