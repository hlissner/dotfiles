# profiles/hardware/printer
#
# Printers exist because there isn't enough despair in the world.

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
{
  services.printing = {
    enable = true;
    startWhenNeeded = true;
    # logLevel = "debug";
  };
}
