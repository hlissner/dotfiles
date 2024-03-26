# modules/profiles/network/ca.nix --- TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "ca" config.modules.profiles.networks) {
  time.timeZone = "America/Toronto";

  # For redshift, mainly
  location = {
    latitude = 43.70011;
    longitude = -79.4163;
  };
}
