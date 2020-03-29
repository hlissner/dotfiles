{ config, options, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.gaming.factorio = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.gaming.factorio.enable {
    my.packages = with pkgs; [
      unstable.factorio-experimental
    ];
  };
}
