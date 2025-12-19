## modules/desktop/hyprland.nix
#
# Sets up a hyprland-based desktop environment.

{ hey, heyBin, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.hyprland;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
in {
  imports = [
    hey.modules.dankMaterialShell.dankMaterialShell
    # hey.modules.dankMaterialShell.greeter
  ];

  options.modules.desktop.hyprland = with types; {
    enable = mkBoolOpt false;
    extraConfig = mkOpt lines "";
    monitors = mkOpt (listOf (submodule {
      options = {
        output = mkOpt str "";
        mode = mkOpt str "preferred";
        position = mkOpt str "auto";
        scale = mkOpt int 1;
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
    modules.desktop.enable = true;

    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Hyprland's aquamarine requires newer MESA drivers.
    hardware.graphics = {
      package = pkgs.unstable.mesa;
      package32 = pkgs.unstable.pkgsi686Linux.mesa;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;

      # package = hey.inputs.hyprland.packages.${final.stdenv.hostPlatform.system}.hyprland;
      # portalPackage = hey.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    programs.dankMaterialShell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      # FIXME: Not working yet
      # greeter = {
      #   enable = true;
      #   compositor.name = "hyprland";
      #   configHome = "/home/${config.user.name}";
      #   # configFiles = [
      #   #   "/home/${config.user.name}/.config/DankMaterialShell/settings.json"
      #   # ];
      # };

      enableSystemMonitoring = true;     # System monitoring widgets (dgop)
      enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    };

    # xdg.portal.configPackages = [ pkgs.xdg-desktop-portal-gtk ];

    modules.services = {
      # Redshift, but for wayland, but I use hyprshade instead, since wlsunset
      # is a bit buggy with nvidia and multiple monitors.
      # wlsunset.enable = true;

      # There's a bug in hypridle that causes hyprlock to not read input after
      # waking up from suspend (hyprwm/hyprlock#101). swayidle doesn't suffer
      # from this issue.
      # hypridle = {
      #   enable = true;
      #   settings = {
      #     before_sleep_cmd = "${heyBin} hook idle --on sleep";
      #     after_sleep_cmd = "${heyBin} hook idle --off sleep";
      #     lock_cmd = "${heyBin} hook idle --on lock";
      #     unlock_cmd = "${heyBin} hook idle --off lock";
      #     ignore_dbus_inhibit = "false";
      #   };
      #   timeouts =
      #     (optionals (cfg.idle.time > 0) [{
      #       timeout = cfg.idle.time;
      #       on-timeout = "${heyBin} hook idle --dim";
      #       on-resume = "${heyBin} hook idle --resume";
      #     }]) ++
      #     (optionals (cfg.idle.autodpms > 0) [{
      #       timeout = cfg.idle.autodpms;
      #       on-timeout = "${heyBin} hook idle --dpms";
      #       on-resume = "${heyBin} hook idle --resume";
      #     }]) ++
      #     (optionals (cfg.idle.autolock > 0) [{
      #       timeout = cfg.idle.autolock;
      #       on-timeout = "${heyBin} hook idle --lock";
      #     }]) ++
      #     (optionals (cfg.idle.autosleep > 0) [{
      #       timeout = cfg.idle.autosleep;
      #       on-timeout = "${heyBin} hook idle --sleep";
      #     }]);
      # };
      # swayidle = {
      #   enable = true;
      #   events = {
      #     before-sleep = "${heyBin} hook idle --on sleep";
      #     after-resume = "${heyBin} hook idle --off sleep";
      #     lock = "${heyBin} hook idle --on lock";
      #     unlock = "${heyBin} hook idle --off lock";
      #   } // (optionalAttrs (cfg.idle.time > 0) {
      #     idlehint = toString cfg.idle.time;
      #   });
      #   timeouts =
      #     (optionals (cfg.idle.time > 0) [{
      #       timeout = cfg.idle.time;
      #       command = "${heyBin} hook idle --on";
      #       resume = "${heyBin} hook idle --off";
      #     }]) ++
      #     (optionals (cfg.idle.autodpms > 0) [{
      #       timeout = cfg.idle.autodpms;
      #       command = "${heyBin} hook idle --on dpms";
      #       resume = "${heyBin} hook idle --off dpms";
      #     }]) ++
      #     (optionals (cfg.idle.autolock > 0) [{
      #       timeout = cfg.idle.autolock;
      #       command = "loginctl lock-session";
      #     }]) ++
      #     (optionals (cfg.idle.autosleep > 0) [{
      #       timeout = cfg.idle.autosleep;
      #       command = "systemctl suspend";
      #     }]);
      # };

      # REVIEW: Get rid of this when wtype adds mouse support (atx/wtype#24).
      ydotool.enable = true;
    };

    environment.systemPackages = with pkgs; [
      ## For Hyprland
      hyprlock       # *fast* lock screen
      xorg.xrandr    # for XWayland windows

      ## For CLIs
      gromit-mpx     # for drawing on the screen
      pamixer        # for volume control
      wlr-randr      # for monitors that hyprctl can't handle
      ## Waiting for NixOS/nixpkgs@7249e6c56141 to reach nixos-unstable
      wf-recorder    # for screencasting
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

    ## Bootloader.
    # I don't use a real login screen. Instead, I activate hyprlock immediately
    # after boot for basic authentication, with a specialized config to make the
    # boot up process smoother. This is enough to stop casual snoopers from
    # getting into my desktops.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = toString (pkgs.writeShellScript "hyprland-wrapper" ''
          trap 'systemctl --user stop hyprland-session.target; sleep 1' EXIT
          exec Hyprland >/dev/null
        '');
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
        # Launch my hyprlock-powered, pseudo-login screen on `hey hook
        # on-startup`.
        startup."05-loginscreen" = ''
          hey.do systemctl --user import-environment \
                 DISPLAY WAYLAND_DISPLAY \
                 XDG_CURRENT_DESKTOP \
                 HYPRLAND_INSTANCE_SIGNATURE
          hey.do hyprlock --immediate
          sleep 0.1
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

      "hypr/hyprland.pre.conf".text = ''
        # config/hypr/hyprland.pre.conf
        # This was automatically generated by NixOS and my dotfiles

        # Bootstrap session
        exec-once = hey hook startup

        ${concatStringsSep "\n" (map
          (v: if v.disable
              then "monitor = ${v.output},disable"
              else "monitor = ${v.output},${v.mode},${v.position},${toString v.scale}")
          cfg.monitors)}

        $PRIMARY_MONITOR = ${primaryMonitor.output or ""}
        ${optionalString (primaryMonitor ? output) ''
          cursor {
            default_monitor = $PRIMARY_MONITOR
          }

          workspace=1,monitor:$PRIMARY_MONITOR,default:true,persistent:true
          workspace=2,monitor:$PRIMARY_MONITOR
          workspace=3,monitor:$PRIMARY_MONITOR
          workspace=4,monitor:$PRIMARY_MONITOR
          workspace=5,monitor:$PRIMARY_MONITOR
          workspace=6,monitor:$PRIMARY_MONITOR
          workspace=7,monitor:$PRIMARY_MONITOR
          workspace=8,monitor:$PRIMARY_MONITOR
          workspace=9,monitor:$PRIMARY_MONITOR

          # Since wayland doesn't have the concept of a primary monitor,
          # XWayland windows may start in unpredictbale places without a hint.
          exec-once = xrandr --output $PRIMARY_MONITOR --primary
        ''}
      '';
      "hypr/hyprland.post.conf".text = cfg.extraConfig;

      "hypr/hyprlock.conf".text =
        let toHyprlockINI = n: v: ''
              ${n} {
                ${concatStringsSep "\n"
                  (mapAttrsToList (n: v: "${n} = ${toString v}") v)}
              }
            '';
        in concatStringsSep "\n" (flatten
          (mapAttrsToList
            (n: v: if isAttrs v
                   then toHyprlockINI n v
                   else map (x: toHyprlockINI (removeSuffix "s" n) x) v)
            (mergeAttrs' [
              {
                general = {
                  grace = 3;
                  hide_cursor = "false";
                  disable_loading_bar = "true";
                };
              }
              cfg.hyprlock.settings
            ])));
    };

    user.packages = with pkgs; [
      (mkLauncherEntry "Toggle night mode" {
        icon = "redshift";
        exec = "dms ipc night toggle";
      })
      (mkLauncherEntry "Hyprpicker: grab RGB at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --rgb -a";
      })
      (mkLauncherEntry "Hyprpicker: grab HSL at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hsl -a";
      })
      (mkLauncherEntry "Hyprpicker: grab hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "dms color pick --hex -a";
      })
    ];
  };
}
