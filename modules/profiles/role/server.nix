# profiles/role/server.nix
#
# Used for headless servers, at home or abroad, with more
# security/automation-minded configuration.

{ hey, lib, config, pkgs, ... }:

with lib;
mkIf (config.modules.profiles.role == "server") {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  systemd = {
    services.clear-log = {
      description = "Clear >1 month-old logs every week";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=21d";
      };
    };
    timers.clear-log = {
      wantedBy = [ "timers.target" ];
      partOf = [ "clear-log.service" ];
      timerConfig.OnCalendar = "weekly UTC";
    };
  };

  powerManagement.cpuFreqGovernor = mkDefault "ondemand";
  virtualisation.docker.enableOnBoot = mkDefault true;
  power.ups.mode = mkDefault "netclient";

  ## Security tweaks
  boot = {
    kernelPackages = mkForce pkgs.linuxKernel.packages.linux_6_12_hardened;
    kernel.sysctl = {
      # The Magic SysRq key is a key combo that allows users connected to the
      # system console of a Linux kernel to perform some low-level commands.
      # Disable it, since we don't need it, and is a potential security concern.
      "kernel.sysrq" = 0;

      # Reverse path filtering causes the kernel to do source validation of
      # packets received from all interfaces. This can mitigate IP spoofing.
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
    };
  };
  # Prevent replacing the running kernel w/o reboot
  security.protectKernelImage = true;

  # Kill processes that pressure + swap
  systemd.oomd.enableSystemSlice = true;
}
