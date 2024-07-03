{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.docker;
in {
  options.modules.services.docker = {
    enable = mkBoolOpt false;
    # portainer.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = with pkgs; [
        docker
        docker-compose
      ];

      environment.variables = {
        DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
        MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";
      };

      user.extraGroups = [ "docker" ];

      modules.shell.zsh.rcFiles = [ "${hey.configDir}/docker/aliases.zsh" ];

      virtualisation = {
        docker = {
          enable = true;
          autoPrune.enable = true;
          enableOnBoot = mkDefault false;
          # listenOptions = [];
        };
      };
    }

    # (mkIf cfg.portainer.enable {
    #   virtualisation.oci-containers.containers.portainer = {
    #     image = "...";
    #     ports = [];
    #     volumes = [];
    #   };
    # })
  ]);
}

# docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
