# For testing software or building my games for other OSes

{ config, lib, pkgs, ... }:
{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  my.user.extraGroups = [ "vboxusers" ];
}
