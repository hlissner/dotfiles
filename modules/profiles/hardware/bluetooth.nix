# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "bluetooth" config.modules.profiles.hardware) {
  hardware.bluetooth.enable = true;

  hardware.bluetooth.settings = {
    General.ControllerMode = "bredr";
    Policy.ReconnectAttempts = 0;
  };

  # Brute force a reset after waking up from sleep, as some bluetooth devices
  # will fail to connect to a system that's been suspended at some point.
  # systemd.services.bluetooth-resume = {
  #   description = "Restart bluetooth after resume";
  #   wantedBy = [ "sleep.target" ];
  #   before = [ "sleep.target" ];
  #   unitConfig.StopWhenUnneeded = true;
  #   preStop = "${pkgs.systemd}/bin/systemctl restart bluetooth.service";
  #   serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
  # };
}
