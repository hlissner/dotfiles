{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.teamviewer;
in {
  options.modules.services.teamviewer = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.teamviewer.enable = true;
  };
}
