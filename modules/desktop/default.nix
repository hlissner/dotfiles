{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop;
    isDarwin = pkgs.stdenv.isDarwin;
    setEnv = name: value:
      if isDarwin
      then {}
      else { environment.sessionVariables.${name} = value; };
in {
  options.modules.desktop = {
    type = with types; mkOpt (nullOr str) null;
  };

  config = mkMerge [
    {
      assertions =
        let isEnabled = _: v: v.enable or false;
            desktopEnvironmentNames = [ "hyprland" ];
            desktopEnvironments = filterAttrs (n: _: elem n desktopEnvironmentNames) cfg;
            hasAnyDesktopChildEnabled = cfg:
              (anyAttrs isEnabled cfg)
              || (anyAttrs (_: v: isAttrs v && anyAttrs isEnabled v) cfg);
            hasDesktopEnvironmentEnabled = anyAttrs isEnabled desktopEnvironments;
        in [
          {
            assertion = (countAttrs isEnabled desktopEnvironments) < 2;
            message = "Can't have more than one desktop environment enabled at a time";
          }
          {
            assertion = hasDesktopEnvironmentEnabled || !(hasAnyDesktopChildEnabled cfg);
            message = "Can't enable a desktop sub-module without a desktop environment";
          }
          {
            assertion = cfg.type != null || !(hasAnyDesktopChildEnabled cfg);
            message = "Downstream desktop module did not set modules.desktop.type";
          }
        ];

      hey.info.desktop.type = cfg.type;
    }

    (mkIf (!isDarwin && cfg.type != null) {
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = with pkgs; [
          ubuntu-classic
          dejavu_fonts
          symbola
          material-symbols
          googlesans-code
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

    (mkIf (!isDarwin && cfg.type == "x11") {
      assertions = [{
        assertion = false;
        message = "The X11 desktop baseline was removed; enable modules.desktop.hyprland instead.";
      }];
    })
  ];
}
