# modules/profiles/networks/ts0 -- tailscale network

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let secrets = config.age.secrets;
in mkIf (elem "ts0" config.modules.profiles.networks) {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";

    authKeyFile = mkIf (secrets ? tailscaleAuthKey) secrets.tailscaleAuthKey.path;
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };

    extraUpFlags = [ "--advertise-tags=tag:${config.user.name}" ];

    extraSetFlags = [
      "--accept-dns=true" # Needed for split-DNS
      "--accept-routes"   # Disable if ts0 causes local connectivity issues
      "--operator=${config.user.name}"  # for user-space tailscale
    ];

    # Off by default. Opening it buys direct peer connections instead of
    # relaying everything through a DERP server.
    openFirewall = true;
  };

  # Reduce wait for tailscale0.auto-connect at startup (otherwise I have to wait
  # an extra 1:30min when the system has no internet).
  systemd.services.tailscaled-autoconnect =
    mkIf (secrets ? tailscaleAuthKey) { serviceConfig.TimeoutStartSec = "20s"; };
}
