# modules/desktop/apps/ue.nix --- https://unrealengine.com
#
# ...

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.apps.ue;
in {
  options.modules.desktop.apps.ue = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      ue4
    ];
  };
}
