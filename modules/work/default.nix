{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.work;
in {
  options.modules.work = {
    enable = mkBoolOpt false;
    vpn = rec {
        enable = mkBoolOpt false;
    };
  };

  config = mkIf cfg.enable {
  user.packages = with pkgs; [
  slack
  teams
  openvpn
  ];
 };

}
