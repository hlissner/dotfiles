{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.docker = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.docker.enable {
    my = {
      packages = with pkgs; [ docker docker-compose ];

      env.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
      env.MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";

      user.extraGroups = [ "docker" ];
      zsh.rc = lib.readFile <config/docker/aliases.zsh>;
    };

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
        enableOnBoot = false;
        # listenOptions = [];
      };
    };
  };
}
