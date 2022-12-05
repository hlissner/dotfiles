{ modulesPath, pkgs, config, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # In case of proprietary wireless drivers
  nixpkgs.config.allowUnfree = true;
  hardware.enableRedistributableFirmware = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_0;
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  environment.systemPackages = with pkgs; [
    nixFlakes
    zsh
    git
  ];

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
}

# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=./installer.nix
# docker run -v $(pwd)/installer.nix:/iso.nix nixos/nix:master nix-build '<nixpkgs/nixos> -A config.system.build.isoImage -I nixos-config=/iso.nix
