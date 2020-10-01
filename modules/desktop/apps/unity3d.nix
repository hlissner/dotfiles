# modules/dev/unity3d.nix --- https://unity.com
#
# I don't use Unity often, but when I do, it's in a team or with students.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.unity3d;
in {
  options.modules.desktop.apps.unity3d = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      unity3d
    ];
  };
}
