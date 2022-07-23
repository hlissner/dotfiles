{ config, lib, ... }:

with builtins;
with lib;
let blocklist = fetchurl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts;
in {
  networking.extraHosts = ''
    192.168.1.1   router.home

    # Hosts
    ${optionalString (config.time.timeZone == "Europe/Copenhagen") ''
        192.168.1.28  ao.home
        192.168.1.20  murasaki.home
        192.168.1.19  shiro.home
      ''}
    ${optionalString (config.time.timeZone == "America/Toronto") ''
        192.168.1.2   ao.home
        192.168.1.3   kiiro.home
        192.168.1.10  kuro.home
        192.168.1.11  shiro.home
        192.168.1.12  midori.home
      ''}

    # Block garbage
    ${optionalString config.services.xserver.enable (readFile blocklist)}
  '';

  ## Location config -- since Toronto is my 127.0.0.1
  time.timeZone = mkDefault "America/Toronto";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";
  # For redshift, mainly
  location = (if config.time.timeZone == "America/Toronto" then {
    latitude = 43.70011;
    longitude = -79.4163;
  } else if config.time.timeZone == "Europe/Copenhagen" then {
    latitude = 55.88;
    longitude = 12.5;
  } else {});

  # So the vaultwarden CLI knows where to find my server.
  modules.shell.vaultwarden.config.server = "vault.lissner.net";
}
