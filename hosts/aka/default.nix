# My HTPC. Mostly so family can organize their media collection.

{ config, lib, ... }:
{
  imports = [
    ../personal.nix   # common settings
    ./hardware-configuration.nix
  ];

  modules = {
    shell.zsh.enable = true;
    services.calibre.enable = true;
    services.jellyfin.enable = true;
    services.ssh.enable = true;
    services.syncthing.enable = true;
  };

  my.zsh.rc = lib.readFile <modules/themes/aquanaut/zsh/prompt.zsh>;

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";

  services.calibre-server.calibre-server = "/data/books";
}
