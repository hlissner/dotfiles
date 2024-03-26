{ self, lib, ... }:

{
  system = "x86_64-linux";

  config = { config, pkgs, modulesPath, ...}: {
    imports = [
      "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ];

    user.name = "nixos";

    boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_1;
    boot.kernelModules = [ "wl" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

    isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  };
}

# $ nix build .#nixosConfigurations.installer.config.system.build.isoImage
# or
# $ hey rebuild --host installer build-iso
