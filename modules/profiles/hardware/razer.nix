# profiles/hardware/razer.nix --- support for razer devices

{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "razer" config.modules.profiles.hardware) {
  hardware.openrazer.enable = true;

  user.extraGroups = [ "plugdev" ];

  environment.systemPackages = with pkgs; [
    # TODO Install polychromatic
  ];
}
