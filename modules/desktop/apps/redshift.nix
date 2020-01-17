# modules/desktop/apps/redshift.nix

{ config, lib, pkgs, ... }:
{
  services.redshift.enable = true;

  # For redshift
  location = (if config.time.timeZone == "America/Toronto" then {
    latitude = 43.70011;
    longitude = -79.4163;
  } else if config.time.timeZone == "Europe/Copenhagen" then {
    latitude = 55.88;
    longitude = 12.5;
  } else {});
}
