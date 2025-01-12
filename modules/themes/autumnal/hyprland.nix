{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
    hCfg = config.modules.desktop.hyprland;
in {
  modules.desktop.hyprland.extraConfig = ''
    env = HYPRCURSOR_THEME,${cfg.gtk.cursorTheme.name}
    env = HYPRCURSOR_SIZE,${toString cfg.gtk.cursorTheme.size}

    general {
      gaps_in = 0
      gaps_out = 0
      border_size = 1
      col.active_border = rgba(e6818388) rgba(363637ff) 45deg
      col.inactive_border = rgba(161617ff)
    }
    decoration {
      rounding = 0
      dim_strength = 0.2
      dim_inactive = true
      dim_special = 0.4
      dim_around = 0.4
      shadow {
        enabled = true
        range = 10
        render_power = 4
        color = rgba(0f0f0f88)
      }
      blur {
        enabled = true
        size = 4
        passes = 1
      }
    }

    # Since we can't focus anything with rofi up anyway, convey this visually.
    layerrule = dimaround, rofi
    layerrule = animation slide top, rofi
  '';

  home.configFile."doom/config.local.el".text = ''
    ;; -*- lexical-binding: t -*-
    (add-to-list 'default-frame-alist '(alpha-background . 95))
    (setq doom-theme 'doom-tomorrow-night)
    (custom-theme-set-faces! 'doom-tomorrow-night
      '(default :background "#1d1f21")
      '(solaire-default-face :background "#191B1A"))
  '';

  home.configFile."waybar/style.css".source = ./config/waybar/style.css;
  modules.services.waybar.settings = {
    main = {
      layer = "top";
      position = "top";
      height = 35;
      margin-bottom = 0;
      modules-left = [
        "clock"
        "tray"
      ];
      modules-center = [
        "hyprland/workspaces"
      ];
      modules-right = [
        "custom/spacer"
        "cpu"
        (let hw = config.modules.profiles.hardware; in
         if any (s: hasPrefix "gpu/nvidia" s) hw
         then "custom/gpu-nvidia"
         else "-")
        "memory"
        "bluetooth"
        "network"
        "battery"
        "backlight"
        "pulseaudio"
        "idle_inhibitor"
        # "privacy"
      ];
      "tray" = {
        "icon-size" = 16;
        "spacing" = 4;
        "show-passive-items" = true;
      };
      # TODO: "custom/gpu-amd" = {}
      # TODO: "custom/gpu-intel" = {}
      "custom/gpu-nvidia" = {
        "exec" = "${heyBin} exec nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits";
        "format" = " {}%";
        "return-type" = "";
        "interval" = 4;
      };
      "custom/spacer" = { "format" = " "; };
      "idle_inhibitor" = {
        "format" = "{icon}";
        "format-icons" = {
          "activated" = "";
          "deactivated" = "";
        };
      };
      "bluetooth" = {
        "format" = "";
        "format-disabled" = "";
        "format-connected" = " {num_connections}";
        "tooltip-format" = "{controller_alias}\t{controller_address}";
        "tooltip-format-connected" = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
      };
      "hyprland/window" = {
        "format" = "{title}";
        "separate-outputs" = true;
      };
      "hyprland/workspaces" = {
        "active-only" = false;
        "all-outputs" = false;
        "disable-scroll" = true;
        "on-click" = "activate";
        "show-special" = false;
        "format" = "{icon}";
        "format-icons" = {
          "active" = "";
          "default" = "";
          "empty" = "";
          "urgent" = "";
          "special" = "";
        };
        "persistent-workspaces" = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
          "6" = [];
        };
      };
      "clock" = {
        "format" = "{:%H:%M - %a %d/%b}";
        "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        "calendar" = {
          "mode"          = "year";
          "mode-mon-col"  = 3;
          "weeks-pos"     = "right";
          "on-scroll"     = 0;
          "format" = {
            "months"   = "<span color  ='#ffead3'><b>{}</b></span>";
            "days"     = "<span color='#ecc6d9'><b>{}</b></span>";
            "weeks"    = "<span color ='#99ffdd'><b>W{}</b></span>";
            "weekdays" = "<span color    ='#ffcc66'><b>{}</b></span>";
            "today"    = "<span color ='#ff6699'><b><u>{}</u></b></span>";
          };
        };
        "actions" = {
          "on-click-right" = "mode";
        };
      };
      "backlight" = {
        "device" = "intel_backlight";
        "format" = "{icon}";
        "format-icons" = ["" "" ""];
        "on-scroll-up" = "brightnessctl set 1%+";
        "on-scroll-down" = "brightnessctl set 1%-";
        "min-length" = 6;
      };
      "cpu" = {
        "format" = "<span weight='bold'></span> {usage}%";
      };
      "memory" = {
        "format" = "<span weight='bold'></span> {}%";
      };
      "battery" = {
        "bat" = "BAT0";
        "states" = {
          # "good" = 95;
          "warning" = 30;
          "critical" = 15;
        };
        "format" = "<span weight='bold'>{icon}</span> {capacity}%";
        # "format-good" = ""; // An empty format will hide the module
        # "format-full" = "";
        "format-icons" = ["" "" "" "" ""];
      };
      "pulseaudio" = {
        # "scroll-step" = 1;
        "format" = "<span weight='bold'>{icon}</span>";
        "format-bluetooth" = "<span weight='bold'>{icon}</span> {volume}%";
        "format-muted" = "<span weight='bold'></span>";
        "format-icons" = {
          "headphones" = "";
          "handsfree" = "";
          "headset" = "";
          "phone" = "";
          "portable" = "";
          "car" = "";
          "default" = ["" ""];
        };
        "on-click" = "pavucontrol";
      };
      "network" = {
        "format-disconnected" = "<span weight='bold'>⚠</span>";
        "format-ethernet" = "";
        "format-linked" = "";
        "format-wifi" = "<span weight='bold'></span> {signalStrength}%";
        "tooltip-format-ethernet" = " {ifname} via {gwaddr}";
        "tooltip-format-wifi" = " {essid}: {ifname} via {gwaddr}";
      };
    };
    osd = {
      mode = "overlay";
      layer = "top";
      position = "bottom";
      width = 512;
      height = 200;
      margin-bottom = 220;
      "hyprland/submap".format = "{}";
      modules-center = [ "hyprland/submap" ];
    };
  };

  modules.desktop.hyprland.mako.settings = {
    background-color = "${cfg.colors.types.panelbg}f2";
    border-color = "${cfg.colors.types.border}ee";
    border-radius = 6;
    border-size = 1;
    default-timeout = 10000;
    font = "${cfg.fonts.sans.name} ${toString cfg.fonts.sans.size}";
    height = 300;
    icon-path =
      let iconDir = "/etc/profiles/per-user/${config.user.name}/share/icons";
      in concatStringsSep ":" [
        "${iconDir}/${cfg.gtk.iconTheme.name}"
        "${iconDir}/gnome"
      ];
    layer = "top";
    max-history = 10;
    max-visible = 10;
    padding = 20;
    progress-color = "${cfg.colors.red}2f";
    sort = "-time";
    text-color = cfg.colors.types.fg;
    width = 420;

    "urgency=high" = {
      background-color = "${cfg.colors.types.border}ee";
      # border-color = "${cfg.colors.types.error}66";
      default-timeout = 0;
      text-color = "#ffffff";
    };
    "urgency=low" = {
      background-color = "${cfg.colors.types.panelbg}dd";
      # border-color = "${cfg.colors.types.border}BB";
      # text-color = cfg.colors.types.panelfg;
      default-timeout = 6000;
    };

    "app-name=Spotify" = {
      # background-color = "${cfg.colors.types.border}DD";
      group-by = "app-name";
      max-icon-size = 150;
      padding = "0,0,0,18";
      icon-location = "right";
    };

    "category=preview" = {
      group-by = "app-name";
      max-icon-size = 150;
      padding = "0,0,0,20";
      icon-location = "right";
    };

    # For 'hey .osd ...' notifications
    "app-name=OSD" = {
      anchor = "bottom-center";
      border-color = "${cfg.colors.types.border}99";
      border-radius = 48;
      border-size = 1;
      default-timeout = 1750;
      font = "${cfg.fonts.icons.name} 32";
      format = "%b";
      group-by = "app-name";
      height = 512;
      on-button-left = "none";
      outer-margin = "0,0,256,0";
      padding = "18,0";
      progress-color = "${cfg.colors.red}66";
      text-alignment = "center";
      width = 512;
    };
    "app-name=OSD category=mic" = {
      progress-color = "${cfg.colors.red}44";
    };
    "app-name=OSD category=lcd" = {
      progress-color = "${cfg.colors.brightred}99";
    };
    "app-name=OSD category=indicator" = {
      width = 150;
      padding = "32,0";
      font = "${cfg.fonts.icons.name} 48";
    };
  };

  modules.desktop.hyprland.hyprlock.settings =
    let monitor = (findFirst (x: x.primary) {} hCfg.monitors).output or "";
    in {
      backgrounds =
        map (m: {
          monitor = m.output;
          path = if cfg.wallpapers ? m.output
                 then cfg.wallpapers."${m.output}".path
                 else if cfg.wallpapers ? "*"
                 then cfg.wallpapers."*".path
                 else "/does/not/exist";
          color = "rgb(000000)";
          blur_size = 4;
          blur_passes = 3;
          noise = 0.0117;
          contrast = 1.3;  # Vibrant!!!
          brightness = if m.primary then 0.75 else 0.40;
          vibrancy = 0.2100;
          vibrancy_darkness = 0.0;
        }) hCfg.monitors;
      input-field = {
        inherit monitor;
        size = "250, 60";
        outline_thickness = 6;
        dots_size = 0.4; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.25; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = "true";
        dots_rounding = "-2"; # -1 default circle, -2 follow input-field rounding
        outer_color = "rgba(29, 31, 30, 0.65)";
        inner_color = "rgba(0, 0, 0, 0)";
        font_color = "rgb(${removePrefix "#" cfg.colors.types.fg})";
        fade_on_empty = "true";
        fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
        placeholder_text = "<i>Enter password...</i>"; # Text rendered in the input box when it's empty.
        hide_input = "false";
        rounding = "-1";  # -1 means complete rounding (circle/oval)
        check_color = "rgb(${removePrefix "#" cfg.colors.magenta})";
        fail_color = "rgb(${removePrefix "#" cfg.colors.red})"; # if authentication failed, changes outer_color and fail message color
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
        fail_transition = 300; # transition time in ms between normal outer_color and fail_color
        swap_font_color = "false";
        position = "0, 130";
        halign = "center";
        valign = "bottom";
      };
      labels = [
        { # time
          inherit monitor;
          text = ''cmd[update:60000] echo "<b><big> $(date +"%H:%M") </big></b>"'';
          color = "rgb(${removePrefix "#" cfg.colors.types.fg})";
          font_size = 130;
          font_family = "${cfg.fonts.sans.name} 12";
          shadow_passes = 1;
          shadow_size = 4;
          position = "0, 100";
          halign = "center";
          valign = "center";
        }
        { # date
          inherit monitor;
          text = ''cmd[update:18000000] echo "<b> "$(date +'%A, %-d %B %Y')" </b>"'';
          color = "rgb(${removePrefix "#" cfg.colors.red})";
          font_size = 32;
          font_family = "${cfg.fonts.sans.name} 12";
          shadow_passes = 1;
          shadow_size = 3;
          position = "0, -5";
          halign = "center";
          valign = "center";
        }
      ];
      shapes = [
        {
          inherit monitor;
          size = "540, 540";
          color = "rgba(29, 31, 30, 0.85)";
          rounding = "-1";
          rotate = 0;
          position = "0, 75";
          halign = "center";
          valign = "center";
        }
      ];
    };

  modules.desktop.term.foot.settings = {
    main = {
      font = "${cfg.fonts.terminal.name}:size=${toString cfg.fonts.terminal.size}";
      dpi-aware = "yes";
      pad = "9x9";
    };
    colors = mapAttrs (_: v: if isString v then removePrefix "#" v else v) {
      alpha = 0.95;
      background = cfg.colors.types.bg;
      foreground = cfg.colors.types.fg;
      selection-foreground = cfg.colors.types.panelfg;
      selection-background = cfg.colors.types.panelbg;
      urls = cfg.colors.types.highlight;
      regular0 = cfg.colors.black;
      regular1 = cfg.colors.red;
      regular2 = cfg.colors.green;
      regular3 = cfg.colors.yellow;
      regular4 = cfg.colors.blue;
      regular5 = cfg.colors.magenta;
      regular6 = cfg.colors.cyan;
      regular7 = cfg.colors.white;
      bright0 = cfg.colors.grey;
      bright1 = cfg.colors.brightred;
      bright2 = cfg.colors.brightgreen;
      bright3 = cfg.colors.brightyellow;
      bright4 = cfg.colors.brightblue;
      bright5 = cfg.colors.brightmagenta;
      bright6 = cfg.colors.brightcyan;
      bright7 = cfg.colors.silver;
    };
  };
}
