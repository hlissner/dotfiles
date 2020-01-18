# My HTPC. Mostly so family can organize their media collection.

{ config, lib, ... }:
{
  imports = [
    ../personal.nix   # common settings
    ./hardware-configuration.nix
    ## Apps
    <modules/shell/zsh.nix>
    ## Services
    <modules/services/ssh.nix>
    <modules/services/plex.nix>
    # <modules/services/jellyfin.nix>
    <modules/services/syncthing.nix>
  ];

  my.zsh.rc = lib.readFile <modules/themes/aquanaut/zsh/prompt.zsh>;

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";
}
