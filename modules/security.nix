{ lib, config, ... }:

{
  ## System security tweaks
  # tmpfs = /tmp is mounted in ram. Doing so makes temp file management speedy
  # on ssd systems, and volatile! Because it's wiped on reboot.
  boot.tmpOnTmpfs = lib.mkDefault true;
  systemd.mounts = lib.mkIf config.boot.tmpOnTmpfs [{
    what = "tmpfs";
    where = "/tmp";
    type = "tmpfs";
    # Added noexec (for added security), and reduced size from 50% to 25%
    options = "mode=1777,strictatime,rw,nosuid,nodev,noexec,size=25%";
  }];
  # If not using tmpfs, which is naturally purged on reboot, we must clean it
  # /tmp ourselves. /tmp should be volatile storage!
  boot.cleanTmpDir = lib.mkDefault (!config.boot.tmpOnTmpfs);

  security.hideProcessInformation = true;
  security.protectKernelImage = true;

  # Fix a security hole in place for backwards compatibility. See desc in
  # nixpkgs/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix
  boot.loader.systemd-boot.editor = false;

  # Change me later!
  user.initialPassword = "nixos";
  users.users.root.initialPassword = "nixos";

  # So we don't have to do this later...
  security.acme.acceptTerms = true;
}
