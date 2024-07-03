# modules/profiles/hardware/cpu/amd.nix

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "cpu/amd" s) hardware) {
    hardware.cpu.amd.updateMicrocode =
      mkDefault config.hardware.enableRedistributableFirmware;

    boot.kernelParams = [ "amd_pstate=active" ];  # For Linux 6.3+
  })

  (mkIf (elem "cpu/amd/raphael" hardware) {
    # Disables scatter/gather which was introduced with kernel version 6.2,
    # which produce completely white or flashing screens when enabled while
    # using the iGPU of Ryzen 7000-series CPUs (Raphael)
    boot.kernelParams = [ "amdgpu.sg_display=0" ];
  })
]
