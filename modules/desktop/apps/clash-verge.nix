{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.clash-verge;
in {
  options.modules.desktop.apps.clash-verge = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.clash-verge-rev;
  };

  config = mkIf cfg.enable {
    user.packages = [ cfg.package ];
  };
}
