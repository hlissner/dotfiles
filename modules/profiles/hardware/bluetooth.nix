# profiles/hardware/bluetooth.nix --- TODO
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "bluetooth" config.modules.profiles.hardware) {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        JustWorksRepairing = "always";
        MultiProfile = "multiple";
        Experimental = true;
      };
      Policy.AutoEnable = true;
    };
    disabledPlugins = [ "sap" ];
  };

  boot.kernelModules = [ "btusb" ];
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    blueman
  ];

  systemd.user.services.blueman-applet.enable = false;

  # Brute force a reset after waking up from sleep, as some bluetooth devices
  # will fail to connect to a system that's been suspended at some point.
  powerManagement.resumeCommands = ''
    ${pkgs.util-linux}/bin/rfkill block bluetooth
    ${pkgs.util-linux}/bin/rfkill unblock bluetooth
  '';
}
