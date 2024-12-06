{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop;
in {
  options.modules.desktop = {
    type = with types; mkOpt (nullOr str) null;
  };

  config = mkMerge [
    {
      assertions =
        let isEnabled = _: v: v.enable or false;
            hasDesktopEnabled = cfg:
              (anyAttrs isEnabled cfg)
              || !(anyAttrs (_: v: isAttrs v && anyAttrs isEnabled v) cfg);
        in [
          {
            assertion = (countAttrs isEnabled cfg) < 2;
            message = "Can't have more than one desktop environment enabled at a time";
          }
          {
            assertion = hasDesktopEnabled cfg;
            message = "Can't enable a desktop sub-module without a desktop environment";
          }
          {
            assertion = cfg.type != null || !(anyAttrs isEnabled cfg);
            message = "Downstream desktop module did not set modules.desktop.type";
          }
        ];

      hey.info.desktop.type = cfg.type;
    }

    (mkIf (cfg.type != null) {
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = with pkgs; [
          ubuntu_font_family
          dejavu_fonts
          symbola
        ];
      };

      environment.systemPackages = with pkgs; [
        libnotify  # notify-send
        xdg-utils
        sox        # for `play` utility
      ];
    })

    (mkIf (cfg.type == "wayland") {
      user.packages = with pkgs.unstable; [
        # Program     Substitutes for
        ripdrag       # xdragon
        wev           # xev
        wl-clipboard  # xclip
        wtype         # xdotool (sorta)
        swappy        # swappy/Snappy/sharex
        slurp         # slop
        swayimg       # feh (as an image previewer)
        imv
      ];

      # Improves latency and reduces stuttering in high load scenarios
      security.pam.loginLimits = [
        { domain = "@users"; item = "rtprio"; type = "-"; value = 1; }
      ];
    })

    (mkIf (cfg.type == "x11") {
      environment.sessionVariables.QT_QPA_PLATFORMTHEME = "gnome";

      # Try really hard to get QT to respect my GTK theme.
      # environment.sessionVariables.GTK_DATA_PREFIX = [ "${config.system.path}" ];
      # environment.sessionVariables.QT_STYLE_OVERRIDE = "kvantum";

      user.packages = with pkgs; [
        feh       # image viewer
        xdragon   # drag'n'drop from the terminal
        xclip
        xdotool
        xorg.xwininfo
        qgnomeplatform        # QPlatformTheme for a better Qt application inclusion in GNOME
        libsForQt5.qtstyleplugin-kvantum # SVG-based Qt5 theme engine plus a config tool and extra theme
      ];

      ## Apps/Services
      services.xserver.displayManager.lightdm.greeters.mini.user = config.user.name;

      services.picom = {
        backend = "glx";
        vSync = true;
        opacityRules = [
          "100:_NET_WM_STATE@:32a = '_NET_WM_STATE_FULLSCREEN'"
          "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
          "0:_NET_WM_STATE@[0]:32a *= '_NET_WM_STATE_HIDDEN'"
          "0:_NET_WM_STATE@[1]:32a *= '_NET_WM_STATE_HIDDEN'"
          "0:_NET_WM_STATE@[2]:32a *= '_NET_WM_STATE_HIDDEN'"
          "0:_NET_WM_STATE@[3]:32a *= '_NET_WM_STATE_HIDDEN'"
          "0:_NET_WM_STATE@[4]:32a *= '_NET_WM_STATE_HIDDEN'"
          "98:class_g = 'xst-256color'"
          "90:class_g = 'xst-scratch'"
        ];
        shadowExclude = [
          # Put shadows on notifications, the scratch popup and rofi only
          "! class_g~='(Rofi|xst-scratch|Dunst)$'"
        ];
        settings = {
          blur-background-exclude = [
            "window_type = 'dock'"
            "window_type = 'desktop'"
            "class_g = 'Rofi'"
            "_GTK_FRAME_EXTENTS@:c"
          ];

          # Unredirect all windows if a full-screen opaque window is detected,
          # to maximize performance for full-screen windows. Known to cause
          # flickering when redirecting/unredirecting windows.
          unredir-if-possible = true;

          # GLX backend: Avoid using stencil buffer, useful if you don't have a
          # stencil buffer. Might cause incorrect opacity when rendering
          # transparent content (but never practically happened) and may not
          # work with blur-background. My tests show a 15% performance boost.
          # Recommended.
          glx-no-stencil = true;

          # Use X Sync fence to sync clients' draw calls, to make sure all draw
          # calls are finished before picom starts drawing. Needed on
          # nvidia-drivers with GLX backend for some users.
          xrender-sync-fence = true;
        };
      };
    })
  ];
}
