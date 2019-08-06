{ config, pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "hlissner";
    configDir = "/home/hlissner/.config/syncthing";
    dataDir = "/home/hlissner/sync";
  };
}
