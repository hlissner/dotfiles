# TODO: Incomple

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.mpd;
in {
  options.modules.services.mpd = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.mpd = {
      enable = true;
    };
  };
}
