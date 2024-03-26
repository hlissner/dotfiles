# modules/profiles/hardware/ssd.nix --- TODO
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
mkIf (elem "ssd" config.modules.profiles.hardware) {
  services =
    let hasZfs = any (x: x ? fsType && x.fsType == "zfs") (attrValues config.fileSystems);
    in {
      fstrim.enable = mkDefault (!hasZfs);
      zfs.trim.enable = mkDefault hasZfs;
    };
  boot.initrd.availableKernelModules = [ "nvme" ];
}
