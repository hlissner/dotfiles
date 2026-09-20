## modules/hyprland/theme.nix

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.hyprland.theme;
in {
  options.modules.hyprland.theme = with types; {
    fonts = {
      mono = mkOpt' str "JetBrainsMono Nerd Font" "Font for terminals and editors";
      sans = mkOpt' str "Fira Sans" "Font for everything else";
      packages = mkOpt' (listOf package) (with pkgs; [
        # For GUIs
        fira
        ubuntu-classic

        # For editors/terminals
        dejavu_fonts
        fira-code
        fira-code-symbols
        symbola
        nerd-fonts.jetbrains-mono

        # For design software
        montserrat
        open-sans
      ]) "Fonts to install system-wide. Must include `mono` and `sans`.";
    };

    cursor = {
      name = mkOpt' str "catppuccin-mocha-dark-cursors" "Cursor theme, by name";
      package = mkOpt' package pkgs.catppuccin-cursors.mochaDark
        "The package shipping `name`. The greeter installs this itself.";
      size = mkOpt' int 32 "Cursor size, in pixels";
    };

    icons = {
      name = mkOpt' str "Dracula" "Icon theme, by name";
      packages = mkOpt' (listOf package)
        (with pkgs; [ tela-circle-icon-theme dracula-icon-theme ])
        "Packages searched for `name`";
    };

    colors = mkOpt' (attrsOf (either str (submodule {
      options = {
        color = mkOpt' str  ""   "A CSS hex color to seed the palette with";
        blend = mkOpt' bool true "Whether to harmonize the color with the scheme";
      };
    }))) {} "Seed colors to harmonize into the generated scheme";

    templates = mkOpt' (attrsOf (submodule {
      options = {
        input_path  = mkOpt' str   "" "The template to render";
        output_path = mkOpt' str   "" "Where to write the rendered template";
        pre_hook    = mkOpt' lines "" "Shell run before the template is written";
        post_hook   = mkOpt' lines "" "Shell run after the template is written";
      };
    })) {} "Templates for Noctalia to render when the theme changes";
  };

  config = mkIf config.modules.hyprland.enable (mkMerge [
    {
      hey.info.theme = {
        # Names only
        fonts = { inherit (cfg.fonts) mono sans; };
        cursor = { inherit (cfg.cursor) name size; };
      };

      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = cfg.fonts.packages;
      };

      environment.systemPackages = [ cfg.cursor.package ] ++ cfg.icons.packages;
    }

    ## So GTK apps respect Noctalia's theme
    {
      # Noctalia reads icon-theme out of gsettings (but never writes it), so the
      # default has to live in dconf to be found by apps. The cursor rides along
      # for anything that asks.
      programs.dconf = {
        enable = true;
        profiles.user.databases = [{
          settings."org/gnome/desktop/interface" = {
            icon-theme = cfg.icons.name;
            cursor-theme = cfg.cursor.name;
            cursor-size = gvariant.mkInt32 cfg.cursor.size;
          };
        }];
      };

      environment.sessionVariables = {
        # nixpkgs ships schemas outside XDG_DATA_DIRS, so gsettings needs pointing.
        GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;
        XCURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = toString cfg.cursor.size;
      };
    }

    ## So QT apps respect Noctalia's theme
    {
      qt = {
        enable = true;
        platformTheme = "qt5ct";
      };
      environment.sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
      };
    }

    # Deploy matugen/noctalia templates
    (let fontSize = 12;
         # An unset key has to disappear rather than land as "": Noctalia would
         # write to the config dir for an empty output_path and run a no-op shell
         # for an empty hook.
         mkTemplate = v: filterAttrs (_: x: x != "") v;
         # A bare string is the common case; the table form is what Noctalia wants.
         mkColor = v: if isString v then { color = v; blend = true; } else v;
         # Just enough of a qt{5,6}ct config for Noctalia's palette to land. The
         # rest of the file is qtct's own defaults and I'd rather not pin those.
         # QFont's string form grew nine fields between Qt5 and Qt6, so `tail` --
         # the weight and everything after it -- is all the two versions disagree on.
         mkQtCt = dir: tail:
           let font = name: ''"${name},${toString fontSize},-1,5,${tail}"'';
           in ''
             [Appearance]
            color_scheme_path=${config.home.configDir}/${dir}/colors/noctalia.conf
            custom_palette=true
            icon_theme=${cfg.icons.name}
            style=Fusion

            [Fonts]
            fixed=${font cfg.fonts.mono}
            general=${font cfg.fonts.sans}
           '';
    in mkIf (cfg.templates != {} || cfg.colors != {}) {
      modules.hyprland.noctalia.settings.theme.templates = {
        enable_builtin_templates = true;
        # gtk3/gtk4 write noctalia.css and point gtk-theme at adw-gtk3; qt drops
        # a colour scheme in qt{5,6}ct's colors/ and nothing else -- no hook, no
        # envvar -- so selecting it is the job below.
        builtin_ids = [ "gtk3" "gtk4" "qt" ];
        enable_community_templates = false;
        custom_colors = mapAttrs (_: mkColor) cfg.colors;
        user = mapAttrs (_: mkTemplate) cfg.templates;
      };

      # Picking the scheme in qt6ct used to be a once-per-machine chore, and
      # the machine I did it on is still wearing the palette its predecessor
      # rendered. Nix owns both configs now, so the chore is gone -- at the
      # price of qtct's GUI no longer being able to save over them.
      home.configFile = {
        "qt5ct/qt5ct.conf".text = mkQtCt "qt5ct" "50,0,0,0,0,0";
        "qt6ct/qt6ct.conf".text = mkQtCt "qt6ct" "400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
      };
    })
  ]);
}
