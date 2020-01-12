{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = config.my.username;
    configDir = "/home/hlissner/.config/syncthing";
    dataDir = "/home/hlissner/sync";
  };
}
