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
      scan-path=${cfg.reposDirectory}
    '';
in {
  options.modules.services.cgit = with types; {
    enable = mkBoolOpt false;
    package = mkOption {
      default = pkgs.cgit-pink;
      type = package;
      description = ''
        Cgit package to use. This defaults to a better-maintained fork of cgit.
      '';
    };
    authorizedKeys = mkOption {
      default = config.user.openssh.authorizedKeys.keys;
      type = listOf str;
    };
    user = mkOpt str "git";
    directory = mkOpt str "/srv/${cfg.user}";
    reposDirectory = mkOpt str "${cfg.directory}/public";
    domain = mkOpt str "git.example.com";
    extraConfig = mkOpt str "";
  };

  config = mkIf cfg.enable {
    users = {
      groups.${cfg.user} = {};
      users.${cfg.user} = {
        createHome = true;
        group = cfg.user;
        home = cfg.directory;
        isSystemUser = true;
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
        shell = "${pkgs.git}/bin/git-shell";
      };
    };
    user.extraGroups = [ cfg.user ];

    systemd.tmpfiles.rules = [
      "z ${cfg.directory} 770 ${cfg.user} ${cfg.user} - -"
      "d ${cfg.reposDirectory} 770 ${cfg.user} ${cfg.user} - -"
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
