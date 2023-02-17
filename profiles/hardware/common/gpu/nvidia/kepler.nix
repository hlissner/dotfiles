# profiles/hardware/common/gpu/nvidia/legacy.nix --- for kepler cards

{ self, lib, config, pkgs, ... }:

{
  imports = [ ./. ];

  # Last one supporting Kepler architecture
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
}
