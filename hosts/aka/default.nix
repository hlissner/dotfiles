# My HTPC. Mostly so family can organize their media collection.

{ config, ... }:
{
  imports = [
    ./.  # import common settings

    <modules/shell/zsh.nix>

    <modules/services/ssh.nix>
    <modules/services/plex.nix>
    # <modules/services/jellyfin.nix>
    <modules/services/syncthing.nix>
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";
}
