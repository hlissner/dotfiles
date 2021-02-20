{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.signal;
in {
  options.modules.desktop.apps.signal = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # If not installed from the bleeding edge, signal will refuse to work.
      unstable.signal-desktop
    ];
  };
}
