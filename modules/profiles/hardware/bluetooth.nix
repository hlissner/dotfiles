# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "bluetooth" config.modules.profiles.hardware) {
  hardware.bluetooth.enable = true;

  # Brute force a reset after waking up from sleep, as some bluetooth devices
  # will fail to connect to a system that's been suspended at some point.
  powerManagement.resumeCommands = ''
    ${pkgs.util-linux}/bin/rfkill block bluetooth
    ${pkgs.util-linux}/bin/rfkill unblock bluetooth
  '';
}
