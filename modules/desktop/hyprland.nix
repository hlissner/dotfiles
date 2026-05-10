## modules/desktop/hyprland.nix
#
# Sets up a hyprland-based desktop environment.
#
# TODO: Investigate bluetuith for bluetooth TUI

{ hey, heyBin, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let inherit (hey.lib.pkgs.for pkgs) mkLauncherEntry;
    cfg = config.modules.desktop.hyprland;
    caelestiaCfg = config.modules.desktop.caelestia;
    terminalCommand = config.modules.desktop.term.default;
    browserCommand =
      if config.modules.desktop.browsers.default != null
      then config.modules.desktop.browsers.default
      else "xdg-open";
    editorCommand = config.modules.editors.default;
    zenWmClass = config.modules.desktop.browsers.zen.wmClass;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
    primaryMonitorName = primaryMonitor.output or "";
    xkbLayout = config.services.xserver.xkb.layout;
    xkbVariant = config.services.xserver.xkb.variant;
    xkbOptions = config.services.xserver.xkb.options;
    caelestiaCli = "${caelestiaCfg.cliPackage}/bin/caelestia";
    caelestiaOwnsWallpaper = caelestiaCfg.enable && caelestiaCfg.wallpaper.enable;
    hasScaledMonitor = any (monitor: (monitor.scale or 1) != 1) cfg.monitors;
    qtPlatform = "wayland;xcb";
    qtPlatformTheme = "qtengine";
    desktopSessionPath = concatStringsSep ":" [
      config.home.binDir
      "${config.home.dir}/.opencode/bin"
      "/etc/profiles/per-user/${config.user.name}/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
    ];
    swaybgWallpaperHook = ''
      ${pkgs.procps}/bin/pkill -x swaybg || true
      ${concatStringsSep "\n"
        (mapAttrsToList
          (output: w: ''
            local wallpaper="${w.path}"
            if [[ -f "$wallpaper" ]]; then
              hey.do swaybg \
                     -o "${output}" \
                     -i "$wallpaper" \
                     -m ${w.mode or "center"} &
            fi
          '')
          config.modules.theme.wallpapers)}
      pgrep -x swaybg >/dev/null && sleep 0.5
    '';
    workspaceLines = concatStringsSep "\n" (map
      (n:
        let suffix = optionalString (n == 1) ",default:true,persistent:true";
            monitorPart = optionalString (primaryMonitorName != "") ",monitor:$PRIMARY_MONITOR";
        in "workspace=${toString n}${monitorPart}${suffix}")
      (range 1 10));
in {
  options.modules.desktop.hyprland = with types; {
    enable = mkBoolOpt false;
    extraConfig = mkOpt lines "";
    monitors = mkOpt (listOf (submodule {
      options = {
        output = mkOpt str "";
        mode = mkOpt str "preferred";
        position = mkOpt str "auto";
        scale = mkOpt (oneOf [ int float ]) 1;
        disable = mkOpt bool false;
        primary = mkOpt bool false;
      };
    })) [{}];
    hyprlock = {
      settings = mkOpt (submodule {
        options = {
          general = mkOpt attrs {};
          input-field = mkOpt attrs {};
          backgrounds = mkOpt (listOf attrs) [];
          labels = mkOpt (listOf attrs) [];
          images = mkOpt (listOf attrs) [];
          shapes = mkOpt (listOf attrs) [];
        };
      }) {};
    };

    idle = {
      time = mkOpt int 600;       # 10 min
      autodpms = mkOpt int 1200;   # 20 min
      autolock = mkOpt int 2400;  # 40 min
      autosleep = mkOpt int 0;
    };
  };

  config = mkIf cfg.enable {
    modules.desktop.type = "wayland";

    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    } // optionalAttrs caelestiaCfg.enable {
      QT_QPA_PLATFORM = qtPlatform;
      QT_QPA_PLATFORMTHEME = qtPlatformTheme;
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    # Hyprland's aquamarine requires newer MESA drivers.
    hardware.graphics = {
      package = pkgs.unstable.mesa.drivers;
      package32 = pkgs.unstable.pkgsi686Linux.mesa.drivers;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
      systemd.setPath.enable = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;

      # package = hey.inputs.hyprland.packages.${final.system}.hyprland;
      # portalPackage = hey.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      # Avoid duplicate portal user units from merged module defaults.
      extraPortals = mkForce (with pkgs.unstable; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ]);
      config.common.default = [ "hyprland" "gtk" ];
    };

    services.dbus.enable = true;

    modules.desktop.caelestia.enable = mkDefault true;

    modules.services = {
      # REVIEW: Get rid of this when wtype adds mouse support (atx/wtype#24).
      ydotool.enable = true;
    };

    # Retrieve the latest versions.
    nixpkgs.overlays = [
      # Avoiding the hyprland input overlays to avoid cachix misses (and not
      # setting programs.hyprland.package because other packages, like
      # pkgs.hyprshade, may reference pkgs.hyprland in their derivations).
      # (prev: final: {
      #   hyprland = hey.inputs.hyprland.packages.${final.system}.hyprland;
      # })
      # hey.inputs.hyprlock.overlays.default
      # hey.inputs.hyprpicker.overlays.default
    ];

    environment.systemPackages = with pkgs.unstable; [
      hyprlock       # *fast* lock screen
      hypridle       # idle management for the Hyprland session
      hyprsunset     # night light/gamma integration
      hyprpicker     # screen-space color picker
      hyprshade      # to apply shaders to the screen
      hyprshot       # instead of grim(shot) or maim/slurp

      ## For Hyprland
      swaybg         # feh (as a wallpaper manager)
      xorg.xrandr    # for XWayland windows
      grim
      slurp
      wf-recorder
      wl-clipboard
      swappy
      app2unit
      cliphist
      playerctl

      ## For CLIs
      gromit-mpx     # for drawing on the screen
      pamixer        # for volume control
      wlr-randr      # for monitors that hyprctl can't handle
      ## Waiting for NixOS/nixpkgs@7249e6c56141 to reach nixos-unstable
      # wf-recorder    # for screencasting
    ];

    systemd.user.targets.hyprland-session = {
      unitConfig = {
        Description = "Hyprland compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    systemd.user.services.hypridle = {
      description = "Hyprland idle daemon";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.unstable.hypridle}/bin/hypridle";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    ## Session entry.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${config.programs.uwsm.package}/bin/uwsm start -eD Hyprland ${config.programs.hyprland.package}/bin/start-hyprland";
        user = config.user.name;
      };
    };
    environment.etc."greetd/environments".text = "Hyprland";

    hey = {
      info.hypr = {
        primaryMonitor = primaryMonitor.output or null;
        monitors = cfg.monitors;
      };
      hooks = {
        # UWSM starts Hyprland; this hook connects product shell services to the
        # live compositor session before visual shell/wallpaper hooks run.
        startup."05-session" = ''
          hey.do systemctl --user import-environment \
                 DISPLAY WAYLAND_DISPLAY \
                 PATH \
                 XDG_CURRENT_DESKTOP \
                 ${optionalString caelestiaCfg.enable "QT_QPA_PLATFORM \\"}
                 ${optionalString caelestiaCfg.enable "QT_QPA_PLATFORMTHEME \\"}
                 ${optionalString caelestiaCfg.enable "QT_WAYLAND_DISABLE_WINDOWDECORATION \\"}
                 ${optionalString caelestiaCfg.enable "QT_AUTO_SCREEN_SCALE_FACTOR \\"}
                 HYPRLAND_INSTANCE_SIGNATURE
          hey.do systemctl --user start hyprland-session.target
          hey .play-sound startup
        '';

        # I'm using this instead of exec= lines in hyprland.conf so I can ensure
        # these aren't run at startup and sequentially (i.e. predictable order,
        # since Hyprland's exec= calls are parallelized).
        reload."95-hyprland" = ''
          for i in $(hyprctl instances -j | jq -r '.[].instance'); do
            echo "Hyprland: reloading instance $i"
            hey.do hyprctl -i ''${i//*\//} reload config-only
          done
        '';
      } // optionalAttrs (!caelestiaOwnsWallpaper) {
        # Set wallpaper according to modules.theme.wallpapers when Caelestia is
        # not the wallpaper owner.
        startup."10-wallpaper" = swaybgWallpaperHook;
        reload."10-wallpaper" = swaybgWallpaperHook;
      };
    };

    home.configFile = {
      "hypr" = {
        source = "${hey.configDir}/hypr";
        recursive = true;
      };

      "hypr/shaders/screen-dim.glsl".text = ''
        precision highp float;
        varying vec2 v_texcoord;
        uniform sampler2D tex;
        void main() {
          gl_FragColor = texture2D(tex, v_texcoord) * 0.3;
        }
      '';

      "hypr/monitors.conf".text = ''
        # Generated by NixOS from modules.desktop.hyprland.monitors.
        ${concatStringsSep "\n" (map
          (v: if v.disable
              then "monitor = ${v.output},disable"
              else "monitor = ${v.output},${v.mode},${v.position},${toString v.scale}")
          cfg.monitors)}
      '';

      "hypr/workspaces.conf".text = ''
        # Generated by NixOS from Axiom host workspace facts.
        $PRIMARY_MONITOR = ${primaryMonitorName}
        ${optionalString (primaryMonitorName != "") ''
          cursor {
            default_monitor = $PRIMARY_MONITOR
          }

          # Since Wayland does not have a global primary monitor concept,
          # XWayland windows need an explicit hint when an output is known.
          exec-once = xrandr --output $PRIMARY_MONITOR --primary
        ''}
        ${workspaceLines}
      '';

      "hypr/custom/env.conf".text = ''
        # Generated by NixOS for Axiom desktop integration.
        env = XDG_CURRENT_DESKTOP,Hyprland
        env = XDG_SESSION_DESKTOP,Hyprland
        env = XDG_SESSION_TYPE,wayland
        env = NIXOS_OZONE_WL,1
        env = MOZ_ENABLE_WAYLAND,1
        env = GTK_USE_PORTAL,1
        ${optionalString caelestiaCfg.enable "env = QT_QPA_PLATFORM,${qtPlatform}"}
        ${optionalString caelestiaCfg.enable "env = QT_QPA_PLATFORMTHEME,${qtPlatformTheme}"}
        ${optionalString caelestiaCfg.enable "env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1"}
        ${optionalString caelestiaCfg.enable "env = QT_AUTO_SCREEN_SCALE_FACTOR,1"}
        env = TERMINAL,${terminalCommand}
        env = BROWSER,${browserCommand}
        env = EDITOR,${editorCommand}
      '';

      "hypr/custom/variables.conf".text = ''
        # Generated by NixOS for host-owned defaults and service boundaries.
        $terminal = ${terminalCommand}
        $fileExplorer = thunar
        $fileManager = thunar
        $browser = ${browserCommand}
        $codeEditor = ${editorCommand}
        $textEditor = ${editorCommand}
        $volumeMixer = pavucontrol
        $settingsApp = pavucontrol
        $taskManager = ${terminalCommand} -e htop
        $caelestia = ${caelestiaCli}
      '';

      "hypr/custom/execs.conf".text = ''
        # Generated by NixOS. UWSM/greetd start Hyprland; this starts Nix-owned user units.
        exec-once = hey hook startup
      '';

      "hypr/custom/rules.conf".text = ''
        # Generated by NixOS for Axiom host application placement.
        windowrule = match:class ^(${zenWmClass}|zen|zen-browser)$, workspace 3 silent
        windowrule = match:class ^(vesktop|discord)$, workspace 4 silent
        windowrule = match:class ^(steam|gamescope)$, workspace 5 silent
        windowrule = match:title ^(Friends List|Steam)$, workspace 5 silent
        windowrule = match:class ^(blueman-manager|nm-connection-editor)$, workspace 8 silent
        windowrule = match:class ^(blueman-manager|nm-connection-editor|org.pulseaudio.pavucontrol)$, float yes
        windowrule = match:title ^(Picture-in-Picture)$, float yes
        windowrule = match:title ^(Picture-in-Picture)$, pin true
        windowrule = match:class .*, suppress_event maximize
        windowrule = match:class ^(gamescope|steam_app_.*)$, immediate true
        windowrule = match:class .*, idle_inhibit fullscreen
        windowrule = match:class ^(mpv|vesktop|discord|gamescope|steam_app_.*)$, idle_inhibit focus
        layerrule = match:namespace caelestia.*, blur true
        layerrule = match:namespace caelestia.*, ignore_alpha 0.79
        layerrule = match:namespace selection, no_anim true
      '';

      "hypr/custom/keybinds.conf".text = ''
        # Generated by NixOS for Axiom host policy and Caelestia entrypoints.
        bind = Super, Space, exec, $caelestia shell drawers toggle launcher
        bind = Super, A, exec, $caelestia shell drawers toggle sidebar
        bind = Ctrl+Alt, Delete, exec, $caelestia shell drawers toggle session
        bind = Super+Shift, L, exec, hyprlock
        bindl = , XF86MonBrightnessUp, exec, $caelestia shell brightness set +10%
        bindl = , XF86MonBrightnessDown, exec, $caelestia shell brightness set 10%-
        bindl = , XF86AudioPlay, exec, $caelestia shell mpris playPause
        bindl = , XF86AudioPause, exec, $caelestia shell mpris playPause
        bindl = , XF86AudioNext, exec, $caelestia shell mpris next
        bindl = , XF86AudioPrev, exec, $caelestia shell mpris previous
        bindl = , XF86AudioStop, exec, $caelestia shell mpris stop

        bindr = Ctrl+Super+Shift, R, exec, systemctl --user stop caelestia-shell.service
        bindr = Ctrl+Super+Alt, R, exec, systemctl --user restart caelestia-shell.service

        bind = Super+Shift, Return, exec, ${terminalCommand}
        bind = Super, B, exec, app2unit -- ${browserCommand}
        bind = Super, E, exec, app2unit -- $fileExplorer
        bind = Super, Q, killactive
        bind = Super, F, fullscreen, 0
        bind = Super+Shift, C, exec, hyprpicker -a

        bindl = , Print, exec, $caelestia screenshot
        bind = Super+Shift, S, exec, $caelestia shell picker openFreeze
        bind = Super+Shift+Alt, S, exec, $caelestia shell picker open
        bind = Super+Alt, R, exec, $caelestia record -s
        bind = Ctrl+Alt, R, exec, $caelestia record
        bind = Super+Shift+Alt, R, exec, $caelestia record -r
        bind = Super, V, exec, $caelestia clipboard
        bind = Super, Period, exec, $caelestia emoji -p

        bind = Super, 1, workspace, 1
        bind = Super, 2, workspace, 2
        bind = Super, 3, workspace, 3
        bind = Super, 4, workspace, 4
        bind = Super, 5, workspace, 5
        bind = Super, 6, workspace, 6
        bind = Super, 7, workspace, 7
        bind = Super, 8, workspace, 8
        bind = Super, 9, workspace, 9
        bind = Super, 0, workspace, 10
        bind = Super+Shift, 1, movetoworkspace, 1
        bind = Super+Shift, 2, movetoworkspace, 2
        bind = Super+Shift, 3, movetoworkspace, 3
        bind = Super+Shift, 4, movetoworkspace, 4
        bind = Super+Shift, 5, movetoworkspace, 5
        bind = Super+Shift, 6, movetoworkspace, 6
        bind = Super+Shift, 7, movetoworkspace, 7
        bind = Super+Shift, 8, movetoworkspace, 8
        bind = Super+Shift, 9, movetoworkspace, 9
        bind = Super+Shift, 0, movetoworkspace, 10

        bind = Super+Shift, R, exec, hey reload
      '';

      "hypr/custom/general.conf".text = ''
        # Generated by NixOS for host policy and module extraConfig.
        ecosystem {
          no_update_news = true
        }

        input {
          # Host keyboard facts come from modules.desktop.input.* and must win
          # over the imported upstream default `kb_layout = us`.
          kb_layout = ${xkbLayout}
          ${optionalString (xkbVariant != "") "kb_variant = ${xkbVariant}"}
          ${optionalString (xkbOptions != "") "kb_options = ${xkbOptions}"}
        }

        ${optionalString hasScaledMonitor ''
          xwayland {
            force_zero_scaling = true
          }
        ''}

        ${cfg.extraConfig}
      '';

      "uwsm/env".text = ''
        export PATH=${escapeShellArg desktopSessionPath}
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export MOZ_ENABLE_WAYLAND=1
        export GTK_USE_PORTAL=1
        ${optionalString caelestiaCfg.enable "export QT_QPA_PLATFORM=${escapeShellArg qtPlatform}"}
        ${optionalString caelestiaCfg.enable "export QT_QPA_PLATFORMTHEME=${qtPlatformTheme}"}
        ${optionalString caelestiaCfg.enable "export QT_WAYLAND_DISABLE_WINDOWDECORATION=1"}
        ${optionalString caelestiaCfg.enable "export QT_AUTO_SCREEN_SCALE_FACTOR=1"}
      '';
    };

    user.packages = with pkgs; [
      (mkLauncherEntry "Color picker: copy hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "hyprpicker -a";
      })
    ];
  };
}
