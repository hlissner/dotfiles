{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.vm.qemu;
in {
  options.modules.desktop.vm.qemu = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
    ];
  };
}

# Creating an image:
#   qemu-img create -f qcow2 disk.img
# Creating a snapshot (don't tamper with disk.img):
#   qemu-img create -f qcow2 -b disk.img snapshot.img
