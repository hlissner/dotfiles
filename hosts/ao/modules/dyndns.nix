{ config, lib, pkgs, ... }:

{
  services.ddclient = {
    enable = true;
    configFile = config.age.secrets.ddclient-config.path;
  };
}
