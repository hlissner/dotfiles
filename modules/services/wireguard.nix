{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.wireguard;
    udpPorts = mapAttrs' (_: cfg: cfg.listenPort) config.networking.wireguard.interfaces;
    interfaces = elem 0 (mapAttrs' (n: _: n) config.networking.interfaces);
    wgInterfaces = elem 0 (mapAttrs' (n: _: n) config.networking.wireguard.interfaces);
in {
  options.modules.services.wireguard = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    networking = {
      firewall.allowedUDPPorts = udpPorts;
      nat.enable = true;
      nat.externalInterface = mkDefault interfaces;
      nat.internalInterfaces = mkDefault wgInterfaces;
    };
  };
}
