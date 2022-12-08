{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.profiles.networks.homelab;
in {
  options.profiles.networks.homelab = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      profiles.server.enable = mkDefault true;
      power.ups.mode = mkDefault "netclient";
    }
  ]);
}
