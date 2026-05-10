# modules/themes/autumnal/default.nix --- a dark, pastel theme

{ hey, heyBin, lib, config, pkgs, ... } @ args:

with lib;
with hey.lib;
let
  cfg = config.modules.theme;
in {
  imports = [ ./hyprland.nix ];

  config = mkIf (cfg.active == "autumnal") (mkMerge [
  {
    user.packages = [ pkgs.tela-circle-icon-theme ];

    modules = {
      theme = {
        fonts = with pkgs; {
          sans.name = "Rubik";
          sans.package = rubik;
          mono.name = "CaskaydiaCove NF";
          mono.package = nerd-fonts.caskaydia-cove;
          terminal.name = "FiraCode Nerd Font Mono";
          terminal.package = nerd-fonts.fira-code;
          packages = [
            lxgw-neoxihei
            material-symbols
            open-sans
            montserrat
            noto-fonts-cjk-sans
            sarasa-gothic
          ];
        };
        gtk = with pkgs; {
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
            size = 32;
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
    };
  }

  (mkIf (config.modules.desktop.type != null) {
    home.configFile = with config.modules; mkMerge [
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
  ]);
}
