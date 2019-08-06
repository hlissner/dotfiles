# Ao -- my home development server

{ config, ... }:

{
  imports = [
    ./.  # import common settings

    ./modules/services/ssh.nix
    ./modules/services/nginx.nix
    ./modules/services/gitea.nix
    ./modules/services/syncthing.nix
    ./modules/shell/zsh.nix
  ];

  networking.hostName = "ao";
  networking.networkmanager.enable = true;
}
