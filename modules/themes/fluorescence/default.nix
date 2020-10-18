# modules/themes/fluorescence/default.nix --- a regal dracula-inspired theme

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let m   = config.modules;
    cfg = m.themes.fluorescence;
in {
  options.modules.themes.fluorescence = with types; {
    enable = mkBoolOpt false;
    wallpaper = mkOpt (either path null) ./config/wallpaper.png;
    loginWallpaper = mkOpt (either path null)
      (toFilteredImage cfg.wallpaper "-gaussian-blur 0x2 -modulate 70 -level 5%");
  };

  config = mkIf cfg.enable (mkMerge [
    # Desktop-agnostic configuration
    {
      home.configFile = mkIf m.shell.tmux.enable {
        "tmux/theme".source = ./config/tmux.conf;
      };
      modules.shell.zsh.rcFiles = [ ./config/zsh/prompt.zsh ];
    }

    # Desktop (X11) theming
    (mkIf config.services.xserver.enable {
      user.packages = with pkgs; [
        unstable.ant-dracula-theme
        paper-icon-theme # for rofi
      ];
      fonts.fonts = [ pkgs.jetbrains-mono ];

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

      services.xserver.displayManager.lightdm = mkMerge [
        # Login screen theme
        {
          greeters.mini.extraConfig = ''
            text-color = "#ff79c6"
            password-background-color = "#1E2029"
            window-color = "#181a23"
            border-color = "#181a23"
          '';
        }

        (mkIf (cfg.loginWallpaper != null) {
          background = cfg.loginWallpaper;
        })
      ];
      home.dataFile = mkIf (cfg.wallpaper != null) {
        "wallpaper".source = cfg.wallpaper;
      };

      modules.desktop.browsers = {
        firefox.userChrome = concatMapStringsSep "\n" readFile [
          ./config/firefox/userChrome.css
        ];
        qutebrowser.userStyles = concatMapStringsSep "\n" toCSSFile [
          ./config/qutebrowser/github.scss
          ./config/qutebrowser/monospace-textareas.scss
          ./config/qutebrowser/quora.scss
          ./config/qutebrowser/stackoverflow.scss
          ./config/qutebrowser/xkcd.scss
          ./config/qutebrowser/youtube.scss
        ];
      };

      home.configFile = mkMerge [
        {
          # This is sourced in the displayManager (see
          # modules/desktop/default.nix) to modularize my Xresources config.
          "xtheme/90-theme".source = ./config/Xresources;
          # GTK
          "gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=Ant-Dracula
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
            gtk-theme-name="Ant-Dracula"
            gtk-icon-theme-name="Paper-Mono-Dark"
            gtk-font-name="Sans 10"
          '';
          # QT4/5 global theme
          "Trolltech.conf".text = "[Qt]\nstyle=Ant-Dracula";
        }
        (mkIf m.desktop.bspwm.enable {
          "bspwm/rc.d/polybar".source = ./config/polybar/run.sh;
          "bspwm/rc.d/theme".source = ./config/bspwmrc;
        })
        (mkIf m.desktop.apps.rofi.enable {
          "rofi/theme" = { source = ./config/rofi; recursive = true; };
        })
        (mkIf (m.desktop.bspwm.enable || m.desktop.stumpwm.enable) {
          "polybar" = { source = ./config/polybar; recursive = true; };
          "dunst/dunstrc".source = ./config/dunstrc;
        })
        (mkIf m.desktop.media.graphics.vector.enable {
          "inkscape/templates/default.svg".source = ./config/inkscape/default-template.svg;
        })
      ];
    })
  ]);
}
