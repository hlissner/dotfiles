## modules/desktop/hyprland.nix
#
# Sets up a hyprland-based desktop environment.
#
# TODO: Investigate bluetuith for bluetooth TUI

{ hey, heyBin, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.hyprland;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
in {
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

    mako.settings = mkOpt attrs {};

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

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
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
      swayidle = {
        enable = true;
        events = {
          before-sleep = "${heyBin} hook idle --on sleep";
          after-resume = "${heyBin} hook idle --off sleep";
          lock = "${heyBin} hook idle --on lock";
          unlock = "${heyBin} hook idle --off lock";
        } // (optionalAttrs (cfg.idle.time > 0) {
          idlehint = toString cfg.idle.time;
        });
        timeouts =
          (optionals (cfg.idle.time > 0) [{
            timeout = cfg.idle.time;
            command = "${heyBin} hook idle --on";
            resume = "${heyBin} hook idle --off";
          }]) ++
          (optionals (cfg.idle.autodpms > 0) [{
            timeout = cfg.idle.autodpms;
            command = "${heyBin} hook idle --on dpms";
            resume = "${heyBin} hook idle --off dpms";
          }]) ++
          (optionals (cfg.idle.autolock > 0) [{
            timeout = cfg.idle.autolock;
            command = "loginctl lock-session";
          }]) ++
          (optionals (cfg.idle.autosleep > 0) [{
            timeout = cfg.idle.autosleep;
            command = "systemctl suspend";
          }]);
      };

      waybar = {
        enable = true;
        primaryMonitor = mkDefault (primaryMonitor.output or "");
      };

      # REVIEW: Get rid of this when wtype adds mouse support (atx/wtype#24).
      ydotool.enable = true;
    };

    # Retrieve the latest versions.
    nixpkgs.overlays = [
      # Avoiding the hyprland input overlays to avoid cachix misses (and not
      # setting programs.hyprland.package because other packages, like
      # pkgs.hyprshade, may reference pkgs.hyprland in their derivations).
      (prev: final: {
        hyprland = hey.inputs.hyprland.packages.${final.system}.hyprland;
        hyprshot = pkgs.unstable.hyprshot;
      })
      hey.inputs.hyprlock.overlays.default
      hey.inputs.hyprpicker.overlays.default
    ];

    environment.systemPackages = with pkgs; [
      # pkgs.unstable doesn't have nixpkgs.overlays applied, so any package
      # referencing hyprland in their derivation must be installed from pkgs.
      hyprlock       # *fast* lock screen
      hyprpicker     # screen-space color picker
      hyprshade      # to apply shaders to the screen
      hyprshot       # instead of grim(shot) or maim/slurp
    ] ++ (with pkgs.unstable; [
      mako           # dunst for wayland
      swaybg         # feh (as a wallpaper manager)

      ## Utilities
      gromit-mpx     # for drawing on the screen
      pamixer        # for volume control
      wf-recorder    # screencasting
      wlr-randr      # for monitors that hyprctl can't handle
      xorg.xrandr    # for XWayland windows
    ]);

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
      hooks = {
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

          # TODO: Theme module should handle this!
          local wallpaper=$XDG_DATA_HOME/wallpaper
          if [[ -f $wallpaper ]]; then
            hey.do swaybg -i $wallpaper &
            sleep 0.5
          fi
        '';

        # I'm using this instead of exec= lines in hyprland.conf so I can ensure
        # these aren't run at startup and sequentially (i.e. predictable order,
        # since Hyprland's exec= calls are parallelized).
        reload."95-hyprland" = ''
          for i in $(hyprctl instances -j | jq -r '.[].instance'); do
            echo "Hyprland: reloading instance $i"
            hey.do hyprctl -i ''${i//*\//} reload config-only
          done
          hey.do makoctl reload
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

      "mako/config".text =
        let toINI = mapAttrsToList (n: v: "${n}=${toString v}");
        in ''
          # config/mako/config -*- mode: ini -*-
          # This was automatically generated by NixOS and my dotfiles
          ${concatStringsSep "\n"
            (toINI ({ "output" = (primaryMonitor.output or ""); }
                    // (filterAttrs (_: v: ! isAttrs v) cfg.mako.settings)))}

          ${concatStringsSep "\n"
            (mapAttrsToList
              (n: v: ''
                [${n}]
                ${concatStringsSep "\n" (toINI v)}
              '')
              (filterAttrs (_: v: isAttrs v) cfg.mako.settings))}

          [mode=dnd]
          invisible=1
        '';
    };

    user.packages = with pkgs; [
      (mkLauncherEntry "Toggle blue light filter" {
        icon = "redshift";
        exec = "hyprshade toggle blue-light-filter";
      })
      (mkLauncherEntry "Hyprpicker: grab RGB at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "hey .picker rgb";
      })
      (mkLauncherEntry "Hyprpicker: grab HSL at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "hey .picker hsl";
      })
      (mkLauncherEntry "Hyprpicker: grab hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "hey .picker hex";
      })
    ];
  };
}
