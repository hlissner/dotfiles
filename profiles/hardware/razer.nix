# profiles/hardware/razer.nix --- support for razer devices

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  hardware.openrazer.enable = true;

  user.extraGroups = [ "plugdev" ];

  environment.systemPackages = with pkgs; [
    # TODO Install polychromatic
  ];
}
