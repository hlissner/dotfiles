{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  time.timeZone = "Europe/Copenhagen";

  # For redshift, mainly
  location = {
    latitude = 55.88;
    longitude = 12.5;
  };
}
