# profiles/hardware/common/gpu/nvidia/turing.nix --- 20-series cards

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  imports = [ ./. ];

  # see NixOS/nixos-hardware#348
  hardware.nvidia = {
    powerManagement.finegrained = true;
    nvidiaPersistenced = true;
  };
}
