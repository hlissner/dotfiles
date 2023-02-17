# profiles/role/workstation.nix
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
{
  boot = {
    # HACK I used to disable mitigations for spectre, meltdown, L1TF, retbleed,
    #   and other CPU vulnerabilities for a marginal performance gain on
    #   non-servers, but it really makes little to no difference on modern CPUs.
    #   It may still be worth it on older Xeons and the like (on workstations)
    #   though. I've preserved this in comments for future reference.
    #
    #   DO NOT COPY AND UNCOMMENT IT BLINDLY! If you're looking for
    #   optimizations, these aren't the droids you're looking for!
    # kernelParams = [ "mitigations=off" ];

    # I'm not a big fan of Grub.
    loader.systemd-boot.enable = mkDefault true;

    # Common kernels across workstations
    initrd.availableKernelModules = [
      "xhci_pci"     # USB 3.0
      "usb_storage"  # USB mass storage devices
      "usbhid"       # USB human interface devices
      "ahci"         # SATA devices on modern AHCI controllers
      "sd_mod"       # SCSI, SATA, and IDE devices
    ];
  };

  # TODO ...
  powerManagement.cpuFreqGovernor = mkDefault "performance";

  # Ensure we always have nmtui/nmcli
  networking.networkmanager.enable = mkDefault true;
  user.extraGroups = [ "networkmanager" ];

  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;
}
