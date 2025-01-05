# Theme modules are a special beast. They're the only modules that are deeply
# intertwined with others, and are solely responsible for aesthetics. Disabling
# a theme module should never leave a system non-functional.

args @ { hey, heyBin, lib, options, config, pkgs, home-manager, ... }:

with lib;
with hey.lib;
let cfg = config.modules.theme;
in {
  imports = mapModules' ./. import;

  options.modules.theme = with types; {
    active = mkOption {
      type = nullOr str;
      default = null;
      apply = v: let theme = builtins.getEnv "THEME"; in
                 if theme != "" then theme else v;
      description = ''
        Name of the theme to enable. Can be overridden by the THEME environment
        variable. Themes can also be hot-swapped with 'hey theme $THEME'.
      '';
    };

    # TODO: Make attrsOf submodule
    wallpapers = mkOpt attrs {
      "*" = {
        mode = "center";
        path = "${hey.themesDir}/${toString cfg.active}/wallpaper.png";
      };
    };

    gtk = mkOpt attrs {};

    preferDark = mkOpt bool true;

    # TODO Use submodules
    fonts = {
      mono = {
        name = mkOpt str "Monospace";
        size = mkOpt float 12.0;
        package = mkOpt package null;
      };
      sans = {
        name = mkOpt str "Sans";
        size = mkOpt float 12.0;
        package = mkOpt package null;
      };
      terminal = {
        name = mkOpt str cfg.fonts.mono.name;
        size = mkOpt float (cfg.fonts.mono.size - 2.5);
        package = mkOpt package cfg.fonts.mono.package;
      };
      icons = {
        name = mkOpt str "Font Awesome 6 Free";
        size = mkOpt float cfg.fonts.sans.size;
        package = mkOpt package pkgs.font-awesome;
      };
      packages = mkOpt (listOf package) [];
    };

    colors = {
      black         = mkOpt str "#000000"; # 0
      red           = mkOpt str "#FF0000"; # 1
      green         = mkOpt str "#00FF00"; # 2
      yellow        = mkOpt str "#FFFF00"; # 3
      blue          = mkOpt str "#0000FF"; # 4
      magenta       = mkOpt str "#FF00FF"; # 5
      cyan          = mkOpt str "#00FFFF"; # 6
      silver        = mkOpt str "#BBBBBB"; # 7
      grey          = mkOpt str "#888888"; # 8
      brightred     = mkOpt str "#FF8800"; # 9
      brightgreen   = mkOpt str "#00FF80"; # 10
      brightyellow  = mkOpt str "#FF8800"; # 11
      brightblue    = mkOpt str "#0088FF"; # 12
      brightmagenta = mkOpt str "#FF88FF"; # 13
      brightcyan    = mkOpt str "#88FFFF"; # 14
      white         = mkOpt str "#FFFFFF"; # 15

      # base0  = mkOpt str "";
      # base1  = mkOpt str "";
      # base2  = mkOpt str "";
      # base3  = mkOpt str "";
      # base4  = mkOpt str "";
      # base5  = mkOpt str "";
      # base6  = mkOpt str "";
      # base7  = mkOpt str "";
      # base8  = mkOpt str "";
      # base9  = mkOpt str "";
      # base10 = mkOpt str "";
      # base11 = mkOpt str "";
      # base12 = mkOpt str "";
      # base13 = mkOpt str "";
      # base14 = mkOpt str "";
      # base15 = mkOpt str "";

      # Color classes
      types = {
        bg        = mkOpt str cfg.colors.black;
        fg        = mkOpt str cfg.colors.white;
        panelbg   = mkOpt str cfg.colors.types.bg;
        panelfg   = mkOpt str cfg.colors.types.fg;
        border    = mkOpt str cfg.colors.types.bg;
        error     = mkOpt str cfg.colors.red;
        warning   = mkOpt str cfg.colors.yellow;
        highlight = mkOpt str cfg.colors.white;
        cursor    = mkOpt str cfg.colors.types.highlight;
      };
    };
  };

  config = mkIf (cfg.active != null) (mkMerge [
    {
      hey.info.theme = {
        inherit (cfg) active colors;
        fonts = mapAttrs
          (_: v: removeAttrs v ["package"])
          (removeAttrs cfg.fonts ["packages"]);
        gtk = {
          theme = { inherit (cfg.gtk.theme) name; };
          iconTheme = { inherit (cfg.gtk.iconTheme) name; };
          cursorTheme = { inherit (cfg.gtk.cursorTheme) name size; };
        };
        wallpapers = cfg.wallpapers;
      };

      home-manager.users.${config.user.name} = {
        gtk = mkAliasDefinitions options.modules.theme.gtk;
        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      };
    }

    # GTK support
    (mkIf (config.modules.desktop.type != null) {
      modules.theme.gtk = {
        enable = true;
        font = mkAliasDefinitions options.modules.theme.fonts.sans;
        gtk2 = {
          extraConfig = "gtk-application-prefer-dark-theme=${boolToStr cfg.preferDark}";
          # Keep $HOME clean, damn it! (Writes to ~/.gtkrc-2.0 otherwise)
          configLocation = "${config.user.home}/.config/gtk-2.0/gtkrc";
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      };

      environment.sessionVariables.GTK2_RC_FILES = [ "$HOME/.config/gtk-2.0/gtkrc" ];
      environment.etc."gtk-2.0/gtkrc".source = config.modules.theme.gtk.gtk2.configLocation;

      # home-manager's home.pointerCursor writes to $HOME/.icons for "backwards
      # compatibility", but I don't use any software that needs this, and I'd
      # rather $HOME be tidy, so I do this manually to avoid its creation.
      environment.sessionVariables.XCURSOR_PATH = mkForce [ "/etc/profiles/per-user/${config.user.name}" "${config.home.dataDir}/icons" ];
      environment.sessionVariables.XCURSOR_THEME = cfg.gtk.cursorTheme.name;
      environment.sessionVariables.XCURSOR_SIZE = toString cfg.gtk.cursorTheme.size;
      home.dataFile = {
        "icons/default/index.theme".source =
          "${cfg.gtk.iconTheme.package}/share/icons/default/index.theme";
        "icons/${cfg.gtk.iconTheme.name}".source =
          "${cfg.gtk.iconTheme.package}/share/icons/${cfg.gtk.iconTheme.name}";
      };

      fonts.packages = [
        cfg.fonts.sans.package
        cfg.fonts.mono.package
        cfg.fonts.terminal.package
        cfg.fonts.icons.package
      ] ++ cfg.fonts.packages;

      fonts.fontconfig.defaultFonts = {
        sansSerif = [ cfg.fonts.sans.name ];
        monospace = [ cfg.fonts.mono.name ];
      };
    })

    (mkIf (config.modules.desktop.type == "x11") (mkMerge [
      {
        # Read xresources files in ~/.config/xtheme/* to allow modular
        # configuration of Xresources.
        hey.hooks.reload."10-xtheme" = ''
          cat "$XDG_CONFIG_HOME"/xtheme/* | ${pkgs.xorg.xrdb}/bin/xrdb -load
        '';

        home.configFile = {
          "xtheme/00-init".text = with cfg.colors; ''
            #define blk  ${black}
            #define red  ${red}
            #define grn  ${green}
            #define ylw  ${yellow}
            #define blu  ${blue}
            #define mag  ${magenta}
            #define cyn  ${cyan}
            #define wht  ${white}
            #define bblk ${grey}
            #define bred ${brightred}
            #define bgrn ${brightgreen}
            #define bylw ${brightyellow}
            #define bblu ${brightblue}
            #define bmag ${brightmagenta}
            #define bcyn ${brightcyan}
            #define bwht ${silver}
            #define bg   ${types.bg}
            #define fg   ${types.fg}
            #define cursor ${types.cursor}

            Xcursor.theme: ${cfg.gtk.cursorTheme.name}
            Xcursor.size: ${toString cfg.gtk.cursorTheme.size}
          '';
          "xtheme/05-colors".text = ''
            *.foreground: fg
            *.background: bg
            *.cursor: cursor
            *.color0:  blk
            *.color1:  red
            *.color2:  grn
            *.color3:  ylw
            *.color4:  blu
            *.color5:  mag
            *.color6:  cyn
            *.color7:  wht
            *.color8:  bblk
            *.color9:  bred
            *.color10: bgrn
            *.color11: bylw
            *.color12: bblu
            *.color13: bmag
            *.color14: bcyn
            *.color15: bwht
          '';
          "xtheme/05-fonts".text = with cfg.fonts.mono; ''
            *.font: xft:${name}:size=${toString size}
            Emacs.font: ${name}:size=${toString size}
          '';
        };
      }

      (mkIf config.modules.desktop.bspwm.enable {
        # To avoid polluting $HOME with .Xresources, I have
        # $XDG_CONFIG_HOME/xtheme/* read while starting up bspwm.
        home.configFile."bspwm/rc.d/05-init" = {
          text = "$XDG_DATA_HOME/dotfiles/10.xtheme.reload";
          executable = true;
        };
      })
    ]))
  ]);
}
