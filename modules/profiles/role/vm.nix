{ self, config, lib, pkgs, ... }:

with lib;
with self.lib;
let platform = config.modules.profiles.platform;
in mkMerge [
  (mkIf (hasPrefix "vm/" platform) {
    boot.zfs.devNodes = "/dev/disk/by-partuuid";
  })

  (mkIf (platform == "vm/qemu-guest") {
    services.qemuGuest.enable = true;
  })
]
