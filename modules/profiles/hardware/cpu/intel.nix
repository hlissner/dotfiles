# modules/profiles/hardware/cpu/intel.nix

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "cpu/intel" s) hardware) {
    hardware.cpu.intel.updateMicrocode =
      mkDefault config.hardware.enableRedistributableFirmware;
  })

  (mkIf (elem "cpu/intel/sandy-bridge" hardware) {
    # Enables RC6, RC6p and RC6pp.
    # Last two are only available on Sandy Bridge CPUs (circa 2011).
    boot.kernelParams = [ "i915.enable_rc6=7" ];
  })

  (mkIf (elem "cpu/intel/kaby-lake" hardware) {
    boot.kernelParams = [ "i915.enable_fbc=1" "i915.enable_psr=2" ];
  })
]
