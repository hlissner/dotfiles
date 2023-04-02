# modules/themes/alucard/default.nix --- a regal dracula-inspired theme

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.theme;
    toCSSFile = file:
      let fileName = removeSuffix ".scss" (baseNameOf file);
          compiledStyles =
            pkgs.runCommand "compileScssFile" { buildInputs = [ pkgs.sass ]; } ''
              mkdir "$out"
              scss --sourcemap=none \
                   --no-cache \
                   --style compressed \
                   --default-encoding utf-8 \
                   "${file}" \
                   >>"$out/${fileName}.css"
            '';
      in "${compiledStyles}/${fileName}.css";
in {
  config = mkIf (cfg.active == "alucard") (mkMerge [
    # Desktop-agnostic configuration
    {
      modules = {
        theme = {
          wallpaper = mkDefault ./config/wallpaper.png;
          gtk = {
            theme = "Dracula";
            iconTheme = "Paper";
            cursorTheme = "Paper";
          };
          fonts = {
            sans.name = "Fira Sans";
            mono.name = "Fira Code";
          };
          colors = {
            black         = "#1E2029";
            red           = "#ffb86c";
            green         = "#50fa7b";
            yellow        = "#f0c674";
            blue          = "#61bfff";
            magenta       = "#bd93f9";
            cyan          = "#8be9fd";
            silver        = "#e2e2dc";
            grey          = "#5B6268";
            brightred     = "#de935f";
            brightgreen   = "#0189cc";
            brightyellow  = "#f9a03f";
            brightblue    = "#8be9fd";
            brightmagenta = "#ff79c6";
            brightcyan    = "#0189cc";
            white         = "#f8f8f2";

            types.fg      = "#bbc2cf";
            types.panelbg = "#21242b";
            types.border  = "#1a1c25";
          };
        };

        shell.zsh.rcFiles  = [ ./config/zsh/prompt.zsh ];
        shell.tmux.rcFiles = [ ./config/tmux.conf ];
        desktop.browsers = {
          firefox.userChrome = concatMapStringsSep "\n" readFile [
            ./config/firefox/userChrome.css
          ];
          qutebrowser.userStyles = concatMapStringsSep "\n" readFile
            (map toCSSFile [
              ./config/qutebrowser/userstyles/monospace-textareas.scss
              ./config/qutebrowser/userstyles/stackoverflow.scss
              ./config/qutebrowser/userstyles/xkcd.scss
            ]);
        };
      };
    }

    # Desktop (X11) theming
    (mkIf config.services.xserver.enable {
      user.packages = with pkgs; [
        dracula-theme
        paper-icon-theme # for rofi
      ];
      fonts = {
        fonts = with pkgs; [
          fira-code
          fira-code-symbols
          open-sans
          jetbrains-mono
          siji
          font-awesome
        ];
      };

      # Compositor
      services.picom = {
        fade = true;
        fadeDelta = 1;
        fadeSteps = [ 0.01 0.012 ];
        shadow = true;
        shadowOffsets = [ (-10) (-10) ];
        shadowOpacity = 0.22;
        # activeOpacity = "1.00";
        # inactiveOpacity = "0.92";
        settings = {
          shadow-radius = 12;
          # blur-background = true;
          # blur-background-frame = true;
          # blur-background-fixed = true;
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
          origin = "top-right";
          offset = "30x30";
          scale = 0;
          transparency = 5;
          corner_radius = 2;
          format = "<b>%s</b>\\n%b";
          frame_color = cfg.colors.types.border;
          frame_width = 1;
          horizontal_padding = 18;
          padding = 16;
          # icon_position = "right";
          icon_theme = "Paper-Mono-Dark, Paper";
          icon_path =
            let iconDir = "/etc/profiles/per-user/${config.user.name}/share/icons";
                iconSize = "24x24";
                mkDirs = themeName:
                  map (dir: "${iconDir}/${themeName}/${iconSize}/${dir}") [
                    "actions"
                    "animations"
                    "apps"
                    "categories"
                    "devices"
                    "emblems"
                    "emotes"
                    "mimetypes"
                    "panel"
                    "places"
                    "status"
                  ];
            in concatStringsSep ":" (flatten (map mkDirs [ "Paper" "gnome" ]));
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
          progress_bar_height = 10;
          progress_bar_frame_width = 1;
          progress_bar_min_width = 150;
          progress_bar_max_width = 300;
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
        };
        urgency_critical = {
          background = cfg.colors.types.bg;
          foreground = cfg.colors.types.warning;
          frame_color = cfg.colors.types.warning;
          timeout = 0;
        };
        osd = {
          stack_tag = "osd";
          height = 150;
          format = "%b";
          timeout = 2;
        };
        low_battery = {
          stack_tag = "battery";
          icon = "battery-empty-charging";
          format = "<b>%s</b> %b";
        };
        spotify = {
          appname = "Spotify";
          max_icon_size = 64;
        };
      };

      # Other dotfiles
      home.configFile = with config.modules; mkMerge [
        {
          # Sourced from sessionCommands in modules/themes/default.nix
          "xtheme/90-theme".source = ./config/Xresources;
        }
        (mkIf desktop.bspwm.enable {
          "bspwm/rc.d/00-theme".source = ./config/bspwmrc;
          "bspwm/rc.d/95-polybar".source = ./config/polybar/run.sh;
        })
        (mkIf desktop.apps.rofi.enable {
          "rofi" = {
            source = ./config/rofi;
            recursive = true;
          };
        })
        (mkIf (desktop.bspwm.enable || desktop.stumpwm.enable) {
          "polybar" = {
            source = ./config/polybar;
            recursive = true;
          };
          "Dracula-purple-solid-kvantum" = {
            recursive = true;
            source = "${pkgs.dracula-theme}/share/themes/Dracula/kde/kvantum/Dracula-purple-solid";
            target = "Kvantum/Dracula-purple-solid";
          };
          "kvantum.kvconfig" = {
            text = "theme=Dracula-purple-solid";
            target = "Kvantum/kvantum.kvconfig";
          };
        })
        (mkIf desktop.media.graphics.vector.enable {
          "inkscape/templates/default.svg".source = ./config/inkscape/default-template.svg;
        })
        (mkIf desktop.browsers.qutebrowser.enable {
          "qutebrowser/extra/theme.py".source = ./config/qutebrowser/theme.py;
        })
      ];
    })
  ]);
}
