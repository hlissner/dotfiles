# ...

device:
{ pkgs, options, lib, config, ... }:
{
  networking.hostName = lib.mkDefault device;

  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    /etc/nixos/hardware-configuration.nix

    ./options/my.nix
    ./options/secrets.nix
    ./secrets.nix
    "${./machines}/${device}.nix"
  ];

  ###
  nix = {
    nixPath = options.nix.nixPath.default ++ [
      "my=/etc/dotfiles"
    ];
    autoOptimiseStore = true;
    trustedUsers = [ "root" ];
  };

  nixpkgs.config = {
    allowUnfree = true;  # forgive me Stallman senpai
    # Occasionally, "stable" packages are broken or incomplete, so access to the
    # bleeding edge is necessary, as a last resort.
    packageOverrides = pkgs: {
      unstable = import <nixpkgs-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # cached-nix-shell, for instant nix-shell scripts
    (callPackage
      (builtins.fetchTarball
        https://github.com/xzfc/cached-nix-shell/archive/master.tar.gz) {})
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?
}
