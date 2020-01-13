# We trained for this. The waves shudder and glare at me through its bright
# tapestry. The clouds see me off as gravity lures me in lazily. How long have I
# been down here? I imagined Jenny leading the team back on a rescue mission and
# it upsets me. It was not worth the risk. We knew what we signed up for.
#
# I hear glass crack. The sea depths hold my waist in a vice. Its strength
# squeezing between the kelvar pockets of my suit. It's hard to breathe. If I
# cut off the oxygen supply perhaps it'd be a nicer way to go.
#
# When did I get so creative?
#
# I can't see further than three feet. Snowflake fractures creep along my visor.
# Would Jorgen be relieved to have a dorm bunk to himself? HQ packs us into our
# subs like sardines. I'll miss his snoring. Maybe I'll catch up on all that
# missed sleep.

{ config, pkgs, ... }:
{
  imports = [ ../. ]; # Load framework for themes

  theme.wallpaper = ./wallpaper.jpg;

  services.compton = {
    activeOpacity = "0.96";
    inactiveOpacity = "0.75";
    settings = {
      blur-background = true;
      blur-background-frame = true;
      blur-background-fixed = true;
      blur-kern = "7x7box";
      blur-strength = 340;
    };
  };

  services.xserver.displayManager.lightdm = {
    greeters.mini.extraConfig = ''
      text-color = "#bbc2cf"
      password-background-color = "#29323d"
      window-color = "#0b1117"
      border-color = "#0b1117"
    '';
  };

  fonts.fonts = [ pkgs.nerdfonts ];
  my.packages = with pkgs; [
    nordic
    paper-icon-theme # for rofi
  ];
  my.home.xdg.configFile = {
    "bspwm/rc.d/polybar".source = ./polybar/run.sh;
    "bspwm/rc.d/theme".source   = ./bspwmrc;
    "dunst/dunstrc".source      = ./dunstrc;
    "polybar" = { source = ./polybar; recursive = true; };
    "rofi/theme" = { source = ./rofi; recursive = true; };
    "tmux/theme".source         = ./tmux.conf;
    "xtheme/90-theme".source    = ./Xresources;
    "zsh/prompt.zsh".source     = ./zsh/prompt.zsh;
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
}
