{ config, lib, pkgs, ... }:

{
  modules.services.cgit = {
    enable = true;
    domain = "git.henrik.io";
    reposDirectory = "/srv/git";
    extraConfig = ''
      robots=noindex, nofollow
      enable-index-owner=0
      enable-http-clone=1
      enable-commit-graph=1
      clone-prefix=https://git.henrik.io
    '';
  };

  services.nginx.virtualHosts."git.henrik.io" = {
    http2 = true;
    forceSSL = true;
    enableACME = true;
  };
}
