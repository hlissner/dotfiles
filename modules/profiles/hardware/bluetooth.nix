# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "bluetooth" config.modules.profiles.hardware) {
  hardware.bluetooth.enable = true;

  hardware.bluetooth.settings = {
    General.ControllerMode = mkDefault "bredr";
    Policy.ReconnectAttempts = 2;
  };
}
