# modules/apps/libreoffice.nix
#
# TODO

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.libreoffice;
in {
  options.modules.apps.libreoffice = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      libreoffice
      (aspellWithDicts (ds: with ds; [ en en-computers en-science ]))
    ];
  };
}
