{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.syncthing;
in {
  options.modules.services.syncthing = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.syncthing = rec {
      enable = true;
      openDefaultPorts = true;
      user = config.user.name;
      configDir = "${config.user.home}/.config/syncthing";
      dataDir = "${config.user.home}/.local/share/syncthing";
    };
  };
}
