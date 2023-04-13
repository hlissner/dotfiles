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

    loader = {
      # I'm not a big fan of Grub, so if it's not in use...
      systemd-boot.enable = mkDefault (!config.boot.loader.grub.enable);
      # For much quicker boot up to NixOS. I can use `systemctl reboot
      # --boot-loader-entry=X` instead.
      timeout = mkDefault 1;
    };

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

  # Use the newer systemd-{network,resolve}d, than resolv or dnsmasq, for a more
  # unified networking backend. It is also required for split-DNS over wireguard
  # (set up using systemd-netdevs, which are more robust than
  # networking.{wg-quick,wireguard}).
  networking = {
    useNetworkd = true;
    networkmanager.dns = "systemd-resolved";  # For split-DNS over wireguard
    # Ensure nmtui/nmcli exist, as they're excellent tools for managing
    # temporary network connections or even swapping wifi networks without
    # having to tango with wpa_supplicant silliness.
    networkmanager.enable = mkDefault true;
  };
  # So the primary user has permission to use the CLI/TUI.
  user.extraGroups = [ "networkmanager" ];

  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;
}
