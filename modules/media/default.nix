{ config, lib, pkgs, ... }:

{
  imports = [
    ./mpv.nix
    # ./ncmpcpp.nix
    ./spotify.nix
  ];
}
