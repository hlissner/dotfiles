{ config, lib, pkgs, ... }:

{
  imports = [
    ./.

    # My launcher
    ./rofi.nix

    # I often need a thumbnail browser to show off, peruse or organize photos,
    # design work, or digital art.
    ./thunar.nix
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

    xst  # st + nice-to-have extensions
    (makeDesktopItem {
      name = "xst";
      desktopName = "Suckless Terminal";
      genericName = "Default terminal";
      icon = "utilities-terminal";
      exec = "${xst}/bin/xst";
      categories = "Development;System;Utility";
    })

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
    (writeScriptBin "st-calc" ''
      #!${stdenv.shell}
      SCRID=st-calc
      scratch=$(xdotool search --onlyvisible --classname $SCRID)
      [ -n "$scratch" ] && xdotool windowkill $scratch
      xst -t $SCRID -n $SCRID -c $SCRID \
          -f "$(xrdb -query | grep 'st-scratch\.font' | cut -f2)" \
          -g 80x12 \
          -e $SHELL -c qalc
    '')
    (makeDesktopItem {
      name = "st-calc";
      desktopName = "Calculator";
      icon = "calc";
      exec = "st-calc";
      categories = "Development";
    })
  ];

  services = {
    xserver = {
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

    compton = {
      enable = true;
      backend = "glx";
      vSync = true;
      opacityRules = [
        "100:class_g = 'Firefox'"
        "100:class_g = 'Vivaldi-stable'"
        "100:class_g = 'VirtualBox Machine'"
        # Art/image programs where we need fidelity
        "100:class_g = 'Gimp'"
        "100:class_g = 'Inkscape'"
        "100:class_g = 'aseprite'"
        "100:class_g = 'krita'"
        "100:class_g = 'feh'"
        "100:class_g = 'mpv'"
      ];
      settings.blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "_GTK_FRAME_EXTENTS@:c"
      ];
    };
  };

  # For polybar
  fonts.fonts = [ pkgs.siji ];

  my = {
    env.PATH = [ <my/config/bspwm/bin> ];
    home.xdg.configFile = {
      "sxhkd".source = <my/config/sxhkd>;
      # link recursively so other modules can link files in their folders
      "bspwm" = { source = <my/config/bspwm>; recursive = true; };
    };
  };
}
