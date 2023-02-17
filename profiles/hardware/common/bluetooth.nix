# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
    hardware.bluetooth.enable = true;
}
