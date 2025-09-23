# profiles/hardware/scanner
#
# TODO

{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
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
