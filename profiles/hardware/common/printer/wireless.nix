# profiles/hardware/printer/wireless.nix --- for wifi printers

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  imports = [ ./. ];

  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };
}
