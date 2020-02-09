{ config, lib, pkgs, ... }:

{
  my.packages = with pkgs; [
    ranger
    (lib.mkIf config.services.xserver.enable
      w3m)
  ];
}
