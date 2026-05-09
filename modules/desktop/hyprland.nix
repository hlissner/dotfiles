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
    quickshellCfg = config.modules.desktop.quickshell;
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

    modules.desktop.quickshell.enable = mkDefault true;

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
      hypridle       # idle management using imported end4 config
      hyprsunset     # night light/gamma integration used by ii
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
      hooks = rec {
        # UWSM starts Hyprland; this hook connects the product shell services to
        # the live compositor session before any visual shell/wallpaper hooks run.
        startup."05-session" = ''
          hey.do systemctl --user import-environment \
                 DISPLAY WAYLAND_DISPLAY \
                 XDG_CURRENT_DESKTOP \
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

        # Set wallpaper according to modules.theme.wallpapers
        startup."10-wallpaper" = ''
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
        reload."10-wallpaper" = startup."10-wallpaper";
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
        # Generated by NixOS for Axiom/end4 integration.
        env = XDG_CURRENT_DESKTOP,Hyprland
        env = XDG_SESSION_DESKTOP,Hyprland
        env = XDG_SESSION_TYPE,wayland
        env = NIXOS_OZONE_WL,1
        env = MOZ_ENABLE_WAYLAND,1
        env = GTK_USE_PORTAL,1
        env = TERMINAL,${terminalCommand}
        env = BROWSER,${browserCommand}
        env = EDITOR,${editorCommand}
        env = ILLOGICAL_IMPULSE_VIRTUAL_ENV,${quickshellCfg.illogicalImpulsePythonEnv}
      '';

      "hypr/custom/variables.conf".text = ''
        # Generated by NixOS for host-owned defaults and service boundaries.
        $terminal = ${terminalCommand}
        $fileManager = thunar
        $browser = ${browserCommand}
        $codeEditor = ${editorCommand}
        $textEditor = ${editorCommand}
        $volumeMixer = pavucontrol
        $settingsApp = qs -p ~/.config/quickshell/${quickshellCfg.configName}/settings.qml
        $taskManager = ${terminalCommand} -e htop
        $qsConfig = ${quickshellCfg.configName}

        # NixOS owns session services; keep upstream visual/general/keybind layers.
        $dontLoadDefaultExecs = 1
        $dontLoadDefaultGeneral =
        $dontLoadDefaultRules =
        $dontLoadDefaultColors =
        $dontLoadDefaultKeybinds =
      '';

      "hypr/custom/execs.conf".text = ''
        # Generated by NixOS. UWSM/greetd start Hyprland; this starts Nix-owned user units.
        exec-once = hey hook startup
        exec-once = sh -c '[ -x "${config.home.stateDir}/quickshell/user/generated/hypr/restore_video_wallpaper.sh" ] && exec "${config.home.stateDir}/quickshell/user/generated/hypr/restore_video_wallpaper.sh" || true'
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
        layerrule = match:namespace selection, no_anim true
      '';

      "hypr/custom/keybinds.conf".text = ''
        # Generated by NixOS for host-level fallbacks that are not end4 visual truth.
        bindd = Super, Space, Toggle launcher, exec, qs -c $qsConfig ipc call startMenu toggle || qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel
        bindd = Super, A, Toggle left sidebar, exec, qs -c $qsConfig ipc call sidebarLeft toggle || true
        bind = Super+Shift, Return, exec, ${terminalCommand}
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

        ${cfg.extraConfig}
      '';

      "uwsm/env".text = ''
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export MOZ_ENABLE_WAYLAND=1
        export GTK_USE_PORTAL=1
        export ILLOGICAL_IMPULSE_VIRTUAL_ENV=${quickshellCfg.illogicalImpulsePythonEnv}
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
