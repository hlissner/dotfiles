# My HTPC. Mostly so family can organize their media collection.

{ config, ... }:
{
  imports = [
    ./.  # import common settings

    <my/modules/services/ssh.nix>
    ./modules/services/plex.nix
    # <my/modules/services/jellyfin.nix>
    <my/modules/shell/zsh.nix>
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";
}
