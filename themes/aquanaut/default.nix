{ config, pkgs, ... }:

{
  imports = [ ../. ]; # Load framework for themes

  environment.systemPackages = with pkgs; [
    nordic
    paper-icon-theme # for rofi
  ];

  fonts.fonts = [ pkgs.nerdfonts ];

  services.compton = {
    backend = "glx";
    activeOpacity = "0.96";
    inactiveOpacity = "0.75";
    opacityRules = [
      "100:class_g = 'Firefox'"
      "100:class_g = 'Gimp'"
      "100:class_g = 'inkscape'"
      "100:class_g = 'aseprite'"
      "100:class_g = 'krita'"
      "100:class_g = 'Peek'"
      "100:class_g = 'feh'"
      "100:class_g = 'mpv'"
    ];
    settings = {
      blur-background = true;
      blur-background-frame = true;
      blur-background-fixed = true;
      blur-kern = "7x7box";
      blur-strength = 340;
      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "class_g = 'Peek'"
        "_GTK_FRAME_EXTENTS@:c"
      ];
    };
  };

  services.xserver.displayManager.lightdm = {
    background = "${./wallpaper.blurred.jpg}";
    greeters.mini.extraConfig = ''
      text-color = "#bbc2cf"
      password-background-color = "#29323d"
      window-color = "#0b1117"
      border-color = "#0b1117"
    '';
  };

  home = {
    home.file.".background-image".source = ./wallpaper.jpg;

    xdg.configFile = {
      "xtheme/90-theme".source = ./Xresources;
      "dunst/dunstrc".source = ./dunstrc;
      "bspwm/rc.d/theme".source = ./bspwmrc;
      "bspwm/rc.d/polybar".source = ./polybar/run.sh;
      "polybar" = { source = ./polybar; recursive = true; };
      "rofi/theme" = { source = ./rofi; recursive = true; };
      "zsh/prompt.zsh".source = ./zsh/prompt.zsh;

      # GTK
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Nordic-blue
        gtk-icon-theme-name=Paper
        gtk-fallback-icon-theme=gnome
        gtk-application-prefer-dark-theme=true
        gtk-cursor-theme-name=Paper
        gtk-xft-hinting=1
        gtk-xft-hintstyle=hintfull
        gtk-xft-rgba=none
      '';

      # GTK2 global theme (widget and icon theme)
      "gtk-2.0/gtkrc".text = ''
        gtk-theme-name="Nordic-blue"
        gtk-icon-theme-name="Paper-Mono-Dark"
        gtk-font-name="Sans 10"
      '';

      # QT4/5 global theme
      "Trolltech.conf".text = ''
        [Qt]
        style=Nordic-blue
      '';
    };
  };
}
