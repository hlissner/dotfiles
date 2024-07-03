{ hey, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in {
  services.picom = {
    shadow = true;
    shadowOffsets = [ (-10) (-10) ];
    shadowOpacity = 0.23;
    settings = {
      shadow-radius = 14;
      blur-kern = "7x7box";
      blur-strength = 320;
    };
  };

  # Login screen theme
  services.xserver.displayManager.lightdm.greeters.mini.extraConfig = ''
    [greeter]
    show-password-label = false

    [greeter-theme]
    text-color = "${cfg.colors.magenta}"
    password-background-color = "${cfg.colors.black}"
    window-color = "${cfg.colors.types.border}"
    border-color = "${cfg.colors.types.border}"
    password-border-radius = 0.01em
    font = "${cfg.fonts.sans.name}"
    font-size = 1.4em
  '';

  modules.services.dunst.settings = {
    global = {
      font = "${cfg.fonts.sans.name} ${toString cfg.fonts.sans.size}";
      follow = "none";
      alignment = "left";
      width = 440;
      height = 300;
      origin = "bottom-center";
      offset = "0x80";
      scale = 0;
      transparency = 2;
      corner_radius = 2;
      format = "<b>%s</b>\\n%b";
      frame_color = cfg.colors.types.border;
      frame_width = 1;
      horizontal_padding = 18;
      padding = 16;
      notification_limit = 10;
      indicate_hidden = "yes";
      icon_position = "left";
      icon_theme = cfg.gtk.iconTheme.name;
      icon_path =
        let iconDir = "/etc/profiles/per-user/${config.user.name}/share/icons";
            iconSizes = [ 8 16 22 24 32 48 64 128 256 512 "scalable" ];
            folders = [
              "actions" "animations" "apps" "categories" "devices" "emblems"
              "emotes" "mimetypes" "notifications" "panel" "places" "status"
              "web"
            ];
            mkDirs = themeName:
              map (dir:
                (map (size:
                  if isString size
                  then "${iconDir}/${themeName}/${size}/${dir}"
                  else [
                    "${iconDir}/${themeName}/${toString size}x${toString size}/${dir}"
                    "${iconDir}/${themeName}/${toString size}x${toString size}@2x/${dir}"
                  ]) iconSizes))
                folders;
        in concatStringsSep ":" (flatten (map mkDirs [ cfg.gtk.iconTheme.name "gnome" ]));
      ignore_newline = false;
      line_height = 0;
      max_icon_size = 24;
      separator_color = "auto";
      separator_height = 4;
      show_age_threshold = 60;
      show_indicators = true;
      shrink = false;
      word_wrap = true;
      # Includes the frame, should be at least 2x as big as the frame width.
      progress_bar_height = 6;
      progress_bar_frame_width = 0;
      progress_bar_min_width = 150;
      progress_bar_max_width = 440;
      # Not in current version of dunst
      # progress_bar_corner_radius = 0;  # disable rounded corners
    };
    urgency_low = {
      background = cfg.colors.types.bg;
      foreground = cfg.colors.types.fg;
      timeout = 8;
      icon = "";
    };
    urgency_normal = {
      background = cfg.colors.types.panelbg;
      foreground = cfg.colors.types.fg;
      timeout = 14;
      icon = "";
      script = "hey .play-sound notify";
    };
    urgency_critical = {
      background = cfg.colors.types.bg;
      foreground = cfg.colors.types.warning;
      frame_color = cfg.colors.types.warning;
      timeout = 0;
      script = "hey .play-sound notify-critical";
    };
    osd = {
      stack_tag = "osd";
      max_icon_size = 512;
      format = "%b";
      timeout = 2;
      icon_position = "top";
      history_ignore = "yes";
      fullscreen = "show";
      hide_text = "true";
      script = "hey .play-sound blip";
    };
    low_battery = {
      stack_tag = "battery";
      icon = "battery-empty-charging";
      format = "<b>%s</b> %b";
      script = "hey .play-sound notify-critical";
    };
    spotify = {
      appname = "Spotify";
      max_icon_size = 64;
    };
  };

  home.configFile = with config.modules; mkMerge [
    {
      # Sourced from sessionCommands in modules/themes/default.nix
      "xtheme/90-theme".source = ./config/Xresources;
    }
    (mkIf desktop.bspwm.enable {
      "bspwm/rc.d/00-theme".source = ./config/bspwmrc;
      "bspwm/rc.d/95-polybar".source = ./config/polybar/run.sh;
    })
    (mkIf desktop.bspwm.enable {
      "polybar" = {
        source = ./config/polybar;
        recursive = true;
      };
      # "Dracula-purple-solid-kvantum" = {
      #   recursive = true;
      #   source = "${pkgs.dracula-theme}/share/themes/Dracula/kde/kvantum/Dracula-purple-solid";
      #   target = "Kvantum/Dracula-purple-solid";
      # };
      # "kvantum.kvconfig" = {
      #   text = "theme=Dracula-purple-solid";
      #   target = "Kvantum/kvantum.kvconfig";
      # };
    })
  ];
}
