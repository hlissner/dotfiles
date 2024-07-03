# modules/system/fs.nix --- TODO
#
# TODO

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.system.fs;
in {
  options.modules.system.fs = {
    enable = mkBoolOpt true;
    zfs.enable = mkBoolOpt (any (x: x ? fsType && x.fsType == "zfs") (attrValues config.fileSystems));
    nfs.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Support for more filesystems (for external drives)
      environment.systemPackages = with pkgs; [
        exfat       # ExFAT drives
        ntfs3g      # Windows drives
        hfsprogs    # MacOS drives
        cryptsetup  # for Luks drives
      ];

      # A daemon that lets us mount/poll disks in userspace. I'd prefer udevil,
      # since it's daemon-less, but it's unmaintained and doesn't understand
      # encrypted filesystems.
      services.udisks2.enable = true;
    }

    (mkIf cfg.zfs.enable (mkMerge [
      {
        boot.loader.grub.copyKernels = true;
        boot.supportedFilesystems = [ "zfs" ];
        services.zfs.autoScrub.enable = true;

        # TODO: services.zfs.autoSnapshot/services.sanoid
      }

      (mkIf cfg.zfs.mail.enable {
        # TODO: services.zfs.zed.enableMail
      })
    ]))

    (mkIf cfg.nfs.enable {
      services.nfs.server.enable = true;
    })
  ]);
}
