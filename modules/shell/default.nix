{ config, lib, pkgs, ... }:

{
  imports = [
    ./direnv.nix
    ./git.nix
    ./gnupg.nix
    ./ncmpcpp.nix
    ./pass.nix
    ./ranger.nix
    ./tmux.nix
    ./weechat.nix
    ./zsh.nix
  ];
}
