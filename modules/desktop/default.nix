{ config, lib, pkgs, ... }:

{
  services.compton = {
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

  my = {
    env.XAUTHORITY = "/tmp/Xauthority";
    init = "[ -e ~/.Xauthority ] && mv -f ~/.Xauthority \"$XAUTHORITY\"";

    packages = with pkgs; [
      libqalculate
      xclip
      xdotool
      mpv       # video player
      feh       # image viewer

      # Useful apps
      calibre   # managing my ebooks
      evince    # pdf reader

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
  };

  fonts.enableFontDir = true;
  fonts.enableGhostscriptFonts = true;
  fonts.fonts = with pkgs; [
    ubuntu_font_family
    dejavu_fonts
    fira-code
    fira-code-symbols
    symbola
    noto-fonts
    noto-fonts-cjk
    font-awesome-ttf
    siji
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = ["Ubuntu"];
    monospace = ["Fira Code"];
  };

  system.activationScripts.clearHome = ''
    pushd /home/${config.my.username}
    rm -rf .compose-cache .nv .pki .dbus .fehbg
    [ -s .xsession-errors ] || rm -f .xsession-errors*
    popd
  '';

  sound.enable = true;
  hardware.pulseaudio.enable = true;
  # Prevents ~/.esd_auth files by disabling the esound protocol module for
  # pulseaudio, which I likely don't need. Is there a better way?
  hardware.pulseaudio.configFile =
    let paConfigFile =
          with pkgs; runCommand "disablePulseaudioEsoundModule"
            { buildInputs = [ pulseaudio ]; } ''
              mkdir "$out"
              cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
              sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
            '';
      in lib.mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";

}
