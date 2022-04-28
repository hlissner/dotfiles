{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.cgit;
    cgitrc = pkgs.writeText "cgitrc" ''
      css=/static/cgit.css
      logo=/static/cgit.png
      favicon=/static/favicon.ico
      root-title=Repositories
      root-desc=Browse repositories
      snapshots=tar.gz zip

      readme=:README
      readme=:readme
      readme=:readme.md
      readme=:README.md
      readme=:readme.org
      readme=:README.org

      ${cfg.extraConfig}

      about-filter=${cfg.package}/lib/cgit/filters/about-formatting.sh
      source-filter=${cfg.package}/lib/cgit/filters/syntax-highlighting.py
      remove-suffix=1
      section-from-path=1
      scan-path=${cfg.repository}
    '';
in {
  options.modules.services.cgit = {
    enable = mkBoolOpt false;
    package = mkOption {
      default = pkgs.cgit-pink;
      type = types.package;
      description = ''
        Cgit package to use. This defaults to a better-maintained fork of cgit.
      '';
    };
    authorizedKeys = mkOption {
      default = config.user.openssh.authorizedKeys.keys;
      type = types.listOf types.str;
    };
    user = mkStrOpt "git";
    directory = mkStrOpt "/srv/${cfg.user}";
    reposDirectory = mkStrOpt "${cfg.directory}/repos";
    domain = mkStrOpt "git.example.com";
    extraConfig = mkStrOpt "";
  };

  config = mkIf cfg.enable {
    users = {
      groups.${cfg.user} = {};
      users.${cfg.user} = {
        createHome = true;
        group = cfg.user;
        home = cfg.reposDirectory;
        isSystemUser = true;
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
        shell = "${pkgs.git}/bin/git-shell";
      };
    };

    systemd.tmpfiles.rules = [
      "z ${cfg.directory} 755 ${cfg.user} ${cfg.user} - -"
      "d ${cfg.repoDirectory} 700 ${cfg.user} ${cfg.user} - -"
    ];

    services.fcgiwrap = {
      enable = true;
      user = cfg.user;
      group = cfg.user;
    };

    services.nginx.enable = true;
    services.nginx.virtualHosts.${cfg.domain} = {
      locations = {
        "~* ^/static/(.+.(ico|css|png))$".extraConfig = ''
          alias ${cfg.package}/cgit/$1;
        '';
        "/".extraConfig = ''
          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_param CGIT_CONFIG ${cgitrc};
          fastcgi_param SCRIPT_FILENAME ${cfg.package}/cgit/cgit.cgi;
          fastcgi_split_path_info ^(/?)(.+)$;
          fastcgi_param PATH_INFO $fastcgi_path_info;
          fastcgi_param HTTP_HOST $server_name;
          fastcgi_param QUERY_STRING $args;
          fastcgi_pass unix:${config.services.fcgiwrap.socketAddress};
        '';
      };
    };
  };
}
