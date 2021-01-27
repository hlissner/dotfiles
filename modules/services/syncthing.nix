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
      configDir = "/home/${user}/.config/syncthing";
      dataDir = "/home/${user}/.local/share/syncthing";
    };
  };
}
