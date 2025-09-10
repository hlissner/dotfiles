# modules/desktop/apps/libreoffice.nix
#
# TODO

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.libreoffice;
in {
  options.modules.desktop.apps.libreoffice = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      libreoffice
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    ];
  };
}
