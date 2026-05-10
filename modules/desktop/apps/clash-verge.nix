{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.clash-verge;
in {
  options.modules.desktop.apps.clash-verge = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.clash-verge-rev;
  };

  config = mkIf cfg.enable {
    programs.clash-verge = {
      enable = true;
      package = cfg.package;
      serviceMode = true;
      tunMode = true;
      autoStart = true;
    };

    networking.firewall = {
      trustedInterfaces = [ "Mihomo" "Meta" ];
      extraReversePathFilterRules = ''
        iifname { "Mihomo", "Meta" } accept comment "trusted mihomo tun interface"
      '';
    };
  };
}
