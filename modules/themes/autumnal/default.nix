# modules/themes/autumnal/default.nix --- a dark, pastel theme

{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in mkIf (cfg.active == "autumnal") (mkMerge [
  {
    user.packages = [ pkgs.unstable.tela-circle-icon-theme ];

    modules = {
      theme = {
        wallpaper = mkDefault ./wallpaper.png;
        fonts = with pkgs.unstable; {
          sans.name = "Fira Sans";
          sans.package = fira;
          mono.name = "JetBrains Mono";
          mono.package = jetbrains-mono;
          packages = [
            fira-code
            fira-code-symbols
            open-sans
            montserrat
          ];
        };
        gtk = with pkgs.unstable; {
          theme = {
            name = "Graphite-pink-Dark";
            package = pkgs.graphite-gtk-theme.override {
              themeVariants = [ "pink" ];
              colorVariants = [ "dark" ];
              # sizeVariants = [ "compact" ];
              tweaks = [
                "normal"
                "rimless"
                "darker"
              ];
            };
          };
          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.catppuccin-papirus-folders.override {
              flavor = "mocha";
              accent = "maroon";
            };
          };
          cursorTheme = {
            name = "catppuccin-mocha-dark-cursors";
            package = catppuccin-cursors.mochaDark;
            size = 48;
          };
        };
        colors = {
          black         = "#1d1f21";
          red           = "#cc6666";
          green         = "#b5bd68";
          yellow        = "#f0c674";
          blue          = "#81a2be";
          magenta       = "#c9b4cf";
          cyan          = "#8abeb7";
          silver        = "#e2e2dc";
          grey          = "#5B6268";
          brightred     = "#de935f";
          brightgreen   = "#0189cc";
          brightyellow  = "#f9a03f";
          brightblue    = "#8be9fd";
          brightmagenta = "#ff79c6";
          brightcyan    = "#0189cc";
          white         = "#C18E76";
          types.fg      = "#c5c8c6";
          types.panelfg = "#e2e2dc";
          types.panelbg = "#161719";
          types.border  = "#0d0d0d";
        };
      };

      shell.zsh.rcFiles  = [ ./config/zsh/prompt.zsh ];
      shell.tmux.rcFiles = [ ./config/tmux.conf ];
      desktop.browsers = {
        firefox = {
          settings."devtools.theme" = "dark";
          userChrome = concatMapStringsSep "\n" readFile [
            ./config/firefox/userChrome.css
          ];
        };
      };
    };
  }

  (mkIf (config.modules.desktop.type != null) {
    modules.desktop.apps.spotify.theme = cfg.active;

    programs.spicetify =
      let spkgs = hey.inputs.spicetify-nix.legacyPackages.${pkgs.system};
      in { theme = spkgs.themes.burntSienna; };

    home.configFile = with config.modules; mkMerge [
      (mkIf desktop.media.graphics.vector.enable {
        "inkscape/templates/default.svg".source = ./config/inkscape/default-template.svg;
      })
      (mkIf desktop.apps.rofi.enable {
        "rofi/config.theme.rasi".source = ./config/rofi/config.rasi;
        "rofi/themes" = {
          source = ./config/rofi/themes;
          recursive = true;
        };
        "rofi/icons" = {
          source = ./config/rofi/icons;
          recursive = true;
        };
      })
    ];
  })

  (mkIf config.modules.desktop.bspwm.enable    (import ./bspwm.nix args))
  (mkIf config.modules.desktop.hyprland.enable (import ./hyprland.nix args))
])
