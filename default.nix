# default.nix --- my dotfile bootstrapper

device:
{ pkgs, options, lib, config, ... }:
{
  networking.hostName = lib.mkDefault device;

  imports = [
    ./options.nix
    "${./hosts}/${device}"
  ];

  ### NixOS
  nix.autoOptimiseStore = true;
  nix.nixPath = options.nix.nixPath.default ++ [
    # So we can use absolute import paths
    "config=/etc/dotfiles/config"
    "modules=/etc/dotfiles/modules"
    # We define nixpkgs-overlays so our overlays will be available to
    # nix-shell/nix-build outside of rebuilding...
    "nixpkgs-overlays=/etc/dotfiles/overlays.nix"
  ];
  # ...but we still need to set nixpkgs.overlays to make them visible to the
  # rebuild process, however...
  nixpkgs.overlays = import ./overlays.nix;
  nixpkgs.config.allowUnfree = true;  # forgive me Stallman senpai

  # For instant nix-shell scripts
  environment.systemPackages = [ pkgs.my.cached-nix-shell ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?
}
