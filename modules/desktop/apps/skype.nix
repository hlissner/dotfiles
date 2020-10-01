{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.skype;
in {
  options.modules.desktop.apps.skype = {
    enable = mkEnableOption false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      skypeforlinux
      skype_call_recorder
    ];
  };
}
