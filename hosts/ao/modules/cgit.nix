{ config, lib, pkgs, ... }:

{
  modules.services.cgit = {
    enable = true;
    domain = "git.henrik.io";
    reposDirectory = "/srv/git";
    extraConfig = ''
      robots=noindex, nofollow
      enable-index-owner=0
    '';
  };

  services.nginx.virtualHosts."git.henrik.io" = {
    http2 = true;
    forceSSL = true;
    enableACME = true;
  };
}
