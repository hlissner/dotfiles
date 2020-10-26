# Theme modules are a special beast. They're the only modules that are deeply
# intertwined with others, and are solely responsible for aesthetics. Disabling
# a theme module should never leave a system non-functional.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.theme;
in {
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

    wallpaper = mkOpt (either path null) null;

    loginWallpaper = mkOpt (either path null)
      (if cfg.wallpaper != null
       then toFilteredImage cfg.wallpaper "-gaussian-blur 0x2 -modulate 70 -level 5%"
       else null);

    gtk = {
      theme = mkOpt str "";
      iconTheme = mkOpt str "";
      cursorTheme = mkOpt str "";
    };

    onReload = mkOpt (attrsOf lines) {};
  };

  config = mkIf (cfg.active != null) (mkMerge [
    # Read xresources files in ~/.config/xtheme/* to allow modular
    # configuration of Xresources.
    (let xrdb = ''${pkgs.xorg.xrdb}/bin/xrdb -merge "$XDG_CONFIG_HOME"/xtheme/*'';
     in {
       services.xserver.displayManager.sessionCommands = xrdb;
       modules.theme.onReload.xtheme = xrdb;
     })

    {
      home.configFile = {
        # GTK
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          ${optionalString (cfg.gtk.theme != "")
            ''gtk-theme-name=${cfg.gtk.theme}''}
          ${optionalString (cfg.gtk.iconTheme != "")
            ''gtk-icon-theme-name=${cfg.gtk.iconTheme}''}
          ${optionalString (cfg.gtk.cursorTheme != "")
            ''gtk-cursor-theme-name=${cfg.gtk.cursorTheme}''}
          gtk-fallback-icon-theme=gnome
          gtk-application-prefer-dark-theme=true
          gtk-xft-hinting=1
          gtk-xft-hintstyle=hintfull
          gtk-xft-rgba=none
        '';
        # GTK2 global theme (widget and icon theme)
        "gtk-2.0/gtkrc".text = ''
          ${optionalString (cfg.gtk.theme != "")
            ''gtk-theme-name="${cfg.gtk.theme}"''}
          ${optionalString (cfg.gtk.iconTheme != "")
            ''gtk-icon-theme-name="${cfg.gtk.iconTheme}"''}
          gtk-font-name="Sans 10"
        '';
        # QT4/5 global theme
        "Trolltech.conf".text = ''
          [Qt]
          ${optionalString (cfg.gtk.theme != "")
            ''style=${cfg.gtk.theme}''}
        '';
      };
    }

    (mkIf (cfg.wallpaper != null)
      (let wCfg = config.services.xserver.desktopManager.wallpaper;
           command = ''
             if [ -e "$XDG_DATA_HOME/wallpaper" ]; then
               ${pkgs.feh}/bin/feh --bg-${wCfg.mode} \
                 ${optionalString wCfg.combineScreens "--no-xinerama"} \
                 --no-fehbg \
                 $XDG_DATA_HOME/wallpaper
             fi
          '';
       in {
         # Set the wallpaper ourselves so we don't need .background-image and/or
         # .fehbg polluting $HOME
         services.xserver.displayManager.sessionCommands = command;
         modules.theme.onReload.wallpaper = command;

         home.dataFile = mkIf (cfg.wallpaper != null) {
           "wallpaper".source = cfg.wallpaper;
         };
       }))

    (mkIf (cfg.loginWallpaper != null) {
      services.xserver.displayManager.lightdm.background = cfg.loginWallpaper;
    })

    (mkIf (cfg.onReload != {})
      (let reloadTheme =
             with pkgs; (writeScriptBin "reloadTheme" ''
               #!${stdenv.shell}
               echo "Reloading current theme: ${cfg.active}"
               ${concatStringsSep "\n"
                 (mapAttrsToList (name: script: ''
                   echo "[${name}]"
                   ${script}
                 '') cfg.onReload)}
             '');
       in {
         user.packages = [ reloadTheme ];
         system.userActivationScripts.reloadTheme = ''
           [ -z "$NORELOAD" ] && ${reloadTheme}/bin/reloadTheme
         '';
       }))
  ]);
}
