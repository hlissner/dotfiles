# modules/system/fs.nix --- TODO
#
# TODO

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.system.fs;
in {
  options.modules.system.fs = {
    enable = mkBoolOpt true;
    zfs = {
      enable = mkBoolOpt (any (x: x ? fsType && x.fsType == "zfs") (attrValues config.fileSystems));
    };
    # TODO automount.enable = mkBoolOpt false;
    nfs.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Support for more filesystems, mostly to support external drives
      environment.systemPackages = with pkgs; [
        sshfs
        exfat       # ExFAT drives
        ntfs3g      # Windows drives
        hfsprogs    # MacOS drives
      ];
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
