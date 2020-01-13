# modules/vm.nix
#
# For testing software or building it on other OSes. If I find out how to get
# macOS on qemu/libvirt I'd be happy to leave virtualbox behind.

{ config, lib, pkgs, ... }:
{
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  my.user.extraGroups = [ "vboxusers" ];
}
