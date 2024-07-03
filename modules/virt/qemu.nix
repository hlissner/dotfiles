{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.virt.qemu;
in {
  options.modules.virt.qemu = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
    ];

    # I will always update the microcode for my CPUs, so this is safe heuristic
    # for what CPU to cater to.
    boot.kernelModules =
      if config.hardware.cpu.amd.updateMicrocode
      then [ "kvm-amd" ]
      else [ "kvm-intel" ];
  };
}

# Creating an image:
#   qemu-img create -f qcow2 disk.img
# Creating a snapshot (don't tamper with disk.img):
#   qemu-img create -f qcow2 -b disk.img snapshot.img
