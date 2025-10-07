# modules/profiles/network/ts0 -- tailscale network

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
mkIf (elem "ts0" config.modules.profiles.networks) (mkMerge [
  {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
  }

  # ...
])
