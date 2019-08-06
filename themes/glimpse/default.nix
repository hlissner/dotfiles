{ config, pkgs, ... }:

{
  imports = [ ../. ]; # Load framework for themes

  environment.systemPackages = with pkgs; [ arc-theme ];

  services.xserver.displayManager.lightdm.background = "${./wallpaper.png}";
  home-manager.users.hlissner = {
    home.file.".background-image".source = ./wallpaper.png;

    xdg.configFile = {
      "xtheme/90-theme".source = ./Xresources;
      "dunst/dunstrc".source = ./dunstrc;
      "bspwm/rc.d/theme".source = ./bspwmrc;
      "bspwm/rc.d/polybar".source = ./polybar/run.sh;
      "rofi/theme".source = ./rofi.theme;
      "polybar" = { source = ./polybar; recursive = true; };

      # GTK
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=Arc-Dark
        gtk-icon-theme-name=Arc-Dark
        gtk-fallback-icon-theme=gnome
        gtk-application-prefer-dark-theme=true
        gtk-cursor-theme-name=Numix
        gtk-xft-hinting=1
        gtk-xft-hintstyle=hintfull
        gtk-xft-rgba=none
      '';

      # GTK2 global theme (widget and icon theme)
      "gtk-2.0/gtkrc".text = ''
        gtk-theme-name="Arc-Dark"
        gtk-icon-theme-name="adwaita"
        gtk-font-name="Sans 10"
      '';

      # QT4/5 global theme
      "Trolltech.conf".text = ''
        [Qt]
        style=Arc-Dark
      '';
    };
  };
}
