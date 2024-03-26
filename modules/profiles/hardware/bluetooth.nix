# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "bluetooth" config.modules.profiles.hardware) {
  hardware.bluetooth.enable = true;
}
