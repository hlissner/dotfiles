{ config, lib, pkgs, ... }:

{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
}
