# modules/desktop/apps/vm.nix
#
# For testing software or building it on other OSes. If I find out how to get
# macOS on qemu/libvirt I'd be happy to leave virtualbox behind.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.desktop.apps.vm = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  # TODO Figure out macOS guest on libvirt/qemu instead
  config = mkIf config.modules.desktop.apps.vm.enable {
    virtualisation.virtualbox.host = {
      enable = true;
      enableExtensionPack = true; # urg, takes so long to build
    };

    my.user.extraGroups = [ "vboxusers" ];
  };
}
