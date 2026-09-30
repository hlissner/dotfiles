# profiles/hardware/scanner
#
# TODO

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "scanner" s) hardware) {
    hardware.sane = {
      enable = true;
      openFirewall = true;
    };
    user.extraGroups = [ "scanner" ];
  })
]
