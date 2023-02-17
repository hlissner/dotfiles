# profiles/hardware/common/ssd.nix --- TODO
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let hasZfs = any (x: x ? fsType && x.fsType == "zfs") (attrValues config.fileSystems);
in {
  services.fstrim.enable = mkDefault (!hasZfs);
  services.zfs.trim.enable = mkDefault hasZfs;
  boot.initrd.availableKernelModules = [ "nvme" ];
}
