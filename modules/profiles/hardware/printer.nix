# profiles/hardware/printer
#
# Printers exist because there isn't enough despair in the world.

{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let hardware = config.modules.profiles.hardware;
in mkMerge [
  (mkIf (any (s: hasPrefix "printer" s) hardware) {
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      # logLevel = "debug";
    };
  })

  (mkIf (elem "printer/wireless" hardware) {
    services.avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
  })
]
