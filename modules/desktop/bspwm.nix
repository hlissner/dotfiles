{ config, lib, pkgs, ... }:

{
  imports = [ ./. ];

  environment = {
    systemPackages = with pkgs; [
      lightdm
      bspwm
      dunst
      libnotify

      (polybar.override {
        mpdSupport = true;
        pulseSupport = true;
        nlSupport = true;
      })
      killall

      rofi
      (writeScriptBin "rofi" ''
        #!${stdenv.shell}
        exec ${rofi}/bin/rofi -config "$XDG_CONFIG_HOME/rofi/config" $@
      '')

      xst  # st + nice-to-have extensions
      # A quick 'n dirty script for opening a scratch terminal.
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
            st -t $SCRID -n $SCRID -c $SCRID \
              -f "$(xrdb -query | grep 'st-scratch\.font' | cut -f2)" \
              -g 100x26 \
              -e $SHELL
        fi
      '')
    ];
  };

  fonts.fonts = [ pkgs.siji ];

  services = {
    xserver = {
      desktopManager.xterm.enable = false;
      displayManager.lightdm.enable = true;
      windowManager.bspwm.enable = true;
    };

    compton = {
      enable = true;
      backend = "glx";
      vSync = "opengl-swc";
      inactiveOpacity = "0.90";
    };
  };

  home-manager.users.hlissner.xdg.configFile = {
    "sxhkd".source = <config/sxhkd>;

    # link recursively so other modules can link files in their folders, e.g.
    # ~/.config/bspwm/rc.d and ~/.config/rofi/theme
    "bspwm" = { source = <config/bspwm>; recursive = true; };
    "rofi" = { source = <config/rofi>; recursive = true; };
  };
}
