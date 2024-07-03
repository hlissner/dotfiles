# modules/profiles/network/dk.nix --- TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "dk" config.modules.profiles.networks) {
  time.timeZone = "Europe/Copenhagen";

  # For redshift, mainly
  location = {
    latitude = 55.88;
    longitude = 12.5;
  };
}
