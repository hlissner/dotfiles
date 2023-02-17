{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  time.timeZone = "America/Toronto";

  # For redshift, mainly
  location = {
    latitude = 43.70011;
    longitude = -79.4163;
  };
}
