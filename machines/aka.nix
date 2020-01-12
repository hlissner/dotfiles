# My HTPC. Runs all my user-facing services and gives me ssh
# access to my work files from anywhere.

{ config, ... }:
{
  imports = [
    ./.  # import common settings

    <my/modules/services/ssh.nix>
    # ./modules/services/plex.nix
    <my/modules/services/jellyfin.nix>
    <my/modules/shell/zsh.nix>
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Toronto";
}
