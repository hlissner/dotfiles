# modules/dev/unity3d.nix --- https://unity.com
#
# I don't use Unity often, but when I do, it's in a team or with students.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.unity3d = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.unity3d.enable {
    my.packages = with pkgs; [
      unity3d
    ];
  };
}
