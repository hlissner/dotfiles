{ hey, config, lib, pkgs, ... }:

with lib;
with hey.lib;
let platform = config.modules.profiles.platform;
in mkMerge [
  (mkIf (hasPrefix "vm/" platform) {
    boot.zfs.devNodes = "/dev/disk/by-partuuid";
  })

  (mkIf (platform == "vm/qemu-guest") {
    services.qemuGuest.enable = true;
  })
]
