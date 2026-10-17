# modules/networking.nix

{ lib, ... }:

{
  # Use systemd-{network,resolve}d; a more unified networking backend that's
  # easier to reconfigure downstream, especially where split-DNS setups (e.g.
  # VPNs) are concerned.
  networking = {
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    # Automatically manage all wired/wireless interfaces.
    networks = {
      "30-wired" = {
        enable = true;
        name = "en*";
        networkConfig.DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = "kernel";
        linkConfig.RequiredForOnline = "no"; # don't hang at boot (if dc'ed)
        dhcpV4Config.RouteMetric = 1024;
      };
      "30-wireless" = {
        enable = true;
        name = "wl*";
        networkConfig.DHCP = "yes";
        networkConfig.IPv6PrivacyExtensions = "kernel";
        linkConfig.RequiredForOnline = "no"; # don't hang at boot (if dc'ed)
        dhcpV4Config.RouteMetric = 2048;     # prefer wired
      };
    };

    # systemd-networkd-wait-online waits forever for *all* interfaces to be
    # online before passing; which is unlikely to ever happen.
    wait-online = {
      # The anyInterface setting is still finnicky for some networks, so I
      # simply turn off the whole check altogether.
      enable = false;
    };
  };
}
