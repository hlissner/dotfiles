# Ao -- my home development and user-facing server

{ config, lib, ... }:

with lib.my;
{
  imports = [
    ../personal.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    shell.git.enable = true;
    shell.zsh.enable = true;
    services.ssh.enable = true;
    services.nginx.enable = true;
    services.gitea.enable = true;
    # services.syncthing.enable = true;

    theme.active = "alucard";
  };


  ## Local config
  networking.networkmanager.enable = true;

  # nginx hosts
  services.nginx = {
    user = config.user.name;
    virtualHosts = {
      "v0.io" = {
        default = true;
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "https://192.168.1.3:8001";
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_pass_header Authorization;
          '';
        };
      };
      "git.v0.io" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:3000";
      };
      # "p.v0.io" = {
      #   enableACME = true;
      #   forceSSL = true;
      #   locations."/".proxyPass = http://127.0.0.1:9001;
      # };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = let email = "henrik@lissner.net"; in {
      "v0.io".email = email;
      "git.v0.io".email = email;
      # "p.v0.io".email = email;
    };
  };

  services.gitea = {
    appName = "V-NOUGHT";
    domain = "v0.io";
    rootUrl = "https://git.v0.io/";
    settings.server.SSH_DOMAIN = "v0.io";
  };

  services.fail2ban = {
    enable = true;
    jails.DEFAULT = ''
      ignoreip = 127.0.0.1/8,192.168.1.0/24
      bantime = 3600
      maxretry = 5
    '';
    jails.sshd = ''
      filter = sshd
      action = iptables[name=ssh, port=22, protocl=tcp]
      enabled = true
    '';
  };
}
