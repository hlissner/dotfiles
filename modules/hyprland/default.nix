## modules/hyprland/default.nix
#
# Sets up a hyprland-based desktop environment.

{ hey, heyBin, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.hyprland;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
in {
  options.modules.hyprland = with types; {
    enable = mkBoolOpt false;
    extraConfig = mkOpt lines "";
    monitors = mkOpt (listOf (submodule {
      options = {
        output = mkOpt str "";
        mode = mkOpt str "preferred";
        position = mkOpt str "auto";
        scale = mkOpt int 1;
        disabled = mkOpt bool false;
        primary = mkOpt bool false;
        vrr = mkOpt int 0;
      };
    })) [{}];
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      systemd.setPath.enable = true;
    };

    programs.dms-shell = {
      enable = true;
      systemd.enable = true;
      enableSystemMonitoring = true;
      enableDynamicTheming = true;
      enableCalendarEvents = false;
    };

    # Needed for changing charge thresholds in Settings > Power & Security >
    # Battery since 26.11 (the setuid wrapper is opt-in from NixOS 26.11+)
    security.polkit.enablePkexecWrapper = true;

    services.greetd.enable = true;

    services.displayManager = {
      # In case I ever want to enable greetd's autologin in the future.
      # dms-greeter greeter doesn't respect this otherwise.
      defaultSession = "hyprland-uwsm";

      dms-greeter = {
        enable = true;
        logs.save = true;
        compositor.name = "hyprland";
        compositor.customConfig = ''
          hl.config({
            misc = {
              background_color = 0xff000000,
              force_default_wallpaper = 0,
              disable_hyprland_logo = true,
              disable_splash_rendering = true
            },
            ecosystem = {
              no_update_news = true,
              no_donation_nag = true
            },
            cursor = {
              inactive_timeout = 1,
              hide_on_key_press = true
            }
          })

          ${optionalString (primaryMonitor ? output) ''
            hl.monitor({ output = "", disabled = true })
            hl.monitor({
              output = "${primaryMonitor.output}",
              mode = "${primaryMonitor.mode}",
              position = "0x0",
              scale = ${toString primaryMonitor.scale}
            })
          ''}
        '';
        # The user's wallpaper and theme, carried onto the login screen. Wants the
        # home directory itself, not $XDG_CONFIG_HOME; the module appends the XDG
        # paths to it.
        configHome = config.home.dir;
      };
    };

    systemd.services.greetd.preStart = mkBefore ''
      # The module's own preStart copies the user's config in but never clears
      # what the last boot left behind.
      rm -f /var/lib/dms-greeter/session.json /var/lib/dms-greeter/wallpaper*
    '';

    environment.systemPackages = with pkgs; [
      ## For Hyprland & DMS
      xrandr         # for XWayland windows
      adw-gtk3       # for DMS
      libinput       # For screenkey plugin

      ## For CLIs
      gromit-mpx     # for drawing on the screen
      wlr-randr      # for monitors that hyprctl can't handle
      wf-recorder    # for screencasting
      quickshell     # for screencast's region indicator
      slurp          # slop
      grim           # screenshot (hyprshot, dms screenshot, etc)
      swappy         # satty/Snappy/sharex

      ## Generic
      libnotify      # notify-send
      xdg-utils
      sox            # for `play` utility

      ## For theme
      catppuccin-cursors.mochaDark
      tela-circle-icon-theme
      dracula-icon-theme
    ];

    fonts = {
      fontDir.enable = true;
      enableGhostscriptFonts = true;
      packages = with pkgs; [
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
      ];
    };

    user.extraGroups = [ "input" ];   # For DMS Screenkey plugin

    ## So DMS+Matugen can theme QT apps
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    };

    modules.hyprland.matugen.templates.hyprland = {
      input_path = "${hey.configDir}/hypr/hyprland-colors.template.lua";
      output_path = "${config.home.configDir}/hypr/hyprland-colors.lua";
    };

    hey = {
      info = {
        hypr = {
          primaryMonitor = primaryMonitor.output or null;
          monitors = cfg.monitors;
        };
        theme.fonts = {
          mono = "JetBrainsMono Nerd Font";
          sans = "Fira Sans";
        };
      };
    };

    modules.shell.zsh.rcFiles = [ "${hey.configDir}/hypr/aliases.zsh" ];

    home.configFile = {
      # If DMS is launched vya systemd, it won't see the profile envvars, so...
      "environment.d/90-dms.conf".text = ''
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
      '';

      "swappy/config".text = ''
        [Default]
        early_exit=true
        save_dir=/run/user/${toString config.user.uid}/swappy/
      '';

      "hypr/hyprland.lua".text = ''
        -- Auto-generated by nixos
        package.path = "${hey.configDir}/hypr/?.lua;" .. package.path

        ${concatStringsSep "\n"
          (map (v: ''
            hl.monitor({
              output = "${v.output}",
              mode = "${v.mode}",
              position = "${v.position}",
              scale = ${toString (v.scale or 1)},
              disabled = ${if v.disabled then "true" else "false"},
              vrr = ${toString (v.vrr or 0)}
            })
          '') cfg.monitors)}

        HOSTNAME = "${config.networking.hostName}"
        ${optionalString (primaryMonitor ? output) ''
          PRIMARY_MONITOR = "${primaryMonitor.output or ""}"
          hl.on("hyprland.start", function ()
              -- Wayland has no concept of a primary monitor, so XWayland
              -- windows may start in unpredictable places without a hint.
              hl.exec_cmd("xrandr --output " .. PRIMARY_MONITOR .. " --primary")
          end)
          hl.config({ cursor = { default_monitor = PRIMARY_MONITOR } })
        ''}

        require("hyprland")
        require("hyprland-post")

        local f = io.open("${hey.configDir}/hypr/hyprland-colors.lua")
        if f ~= nil then
            io.close(f)
        else
            require("hyprland-colors")  -- generated by mutagen
        end
      '';

      "hypr/hyprland-post.lua".text = cfg.extraConfig;
    };

    user.packages = with pkgs; [
      # Program     Substitutes for
      ripdrag       # xdragon
      wev           # xev
      wl-clipboard  # xclip
      wtype         # xdotool (sorta)
      swayimg       # feh (as an image previewer)
      imv

      (mkLauncherEntry "Toggle night mode" {
        icon = "redshift";
        exec = "dms ipc night toggle";
      })
      (mkLauncherEntry "Color picker: grab RGB at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --rgb -a";
      })
      (mkLauncherEntry "Color picker: grab HSL at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hsl -a";
      })
      (mkLauncherEntry "Color picker: grab hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hex -a";
      })
    ];
  };
}
