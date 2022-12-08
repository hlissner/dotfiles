{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.profiles.server;
in {
  options.profiles.server = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    powerManagement.cpuFreqGovernor = mkDefault "ondemand";
    virtualisation.docker.enableOnBoot = mkDefault true;
  };
}
