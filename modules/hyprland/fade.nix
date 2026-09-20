# modules/hyprland/fade.nix
#
# Fade the screen to black before the session goes away.

{ hey, lib, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.modules.hyprland.fade;
in {
  options.modules.hyprland.fade = with types; {
    duration = mkOpt' int 1250 ''
      How long the fade takes, in milliseconds. This is dead time on the way
      down: config/rofi/bin/powermenu.zsh waits for the hook to finish before it
      calls systemctl, so the screen is black by the time the system goes away.
      Budget another ~130ms on top, which is what cold-starting the overlay's
      quickshell costs before the fade can begin.
    '';

    color = mkOpt' str "#000000"
      "What to fade to. Anything QML parses as a color.";
  };

  # No switch of its own: any desktop that gets this far has the hooks to drive
  # a fade, and there's no host that wants one without the other.
  config = mkIf config.modules.hyprland.enable {
    # Needed by config/hypr/bin/fade.zsh
    hey.info.hypr.fade = { inherit (cfg) duration color; };

    # Already pulled in by the parent module for screencast's region indicator,
    # but the fade overlay is a quickshell config too; I prefer to be explicit.
    environment.systemPackages = [ pkgs.quickshell ];

    assertions = [
      {
        assertion = cfg.duration > 0;
        message = "modules.hyprland.fade.duration must be a positive number of milliseconds.";
      }

      # color is a bare string representing QML's color type. A malformed one is
      # the silent failure. Qt expects either a hex literal or an SVG color
      # name.
      {
        assertion =
          let hex = match "#([0-9a-fA-F]+)" cfg.color;
          in if hex != null
             then elem (stringLength (head hex)) [ 3 6 8 9 12 ]
             else match "[a-zA-Z]+" cfg.color != null;
        message = ''
          modules.hyprland.fade.color must be a hex literal (#rgb, #rrggbb or
          #aarrggbb) or an SVG color name, not "${cfg.color}".
        '';
      }
    ];
  };
}
