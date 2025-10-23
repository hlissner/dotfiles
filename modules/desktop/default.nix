{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop;
in {
  options.modules.desktop = {
    enable = mkBoolOpt false;
  };

  config = {
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
      ];

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
  };
}
