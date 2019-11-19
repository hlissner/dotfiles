# My HTPC. Runs all my user-facing services and gives me ssh
# access to my work files from anywhere.

{ config, ... }:

{
  imports = [
    ./.  # import common settings

    ./modules/services/ssh.nix
    ./modules/services/plex.nix
    ./modules/shell/zsh.nix
  ];

  networking.hostName = "aka";
  networking.networkmanager.enable = true;
}
