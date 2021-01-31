{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.nginx;
in {
  options.modules.services.nginx = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    user.extraGroups = [ "nginx" ];

    services.nginx = {
      enable = true;

      # Use recommended settings
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      # Reduce the permitted size of client requests, to reduce the likelihood
      # of buffer overflow attacks. This can be tweaked on a per-vhost basis, as
      # needed.
      clientMaxBodySize = "128k";  # default 10m
      commonHttpConfig = ''
        client_body_buffer_size  4k;       # default: 8k
        large_client_header_buffers 2 4k;  # default: 4 8k
      '';
    };
  };
}

# Helpful nginx snippets
#
# Set expires headers for static files and turn off logging.
#   location ~* ^.+\.(js|css|swf|xml|txt|ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|r ss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav |bmp|rtf)$ {
#     access_log off; log_not_found off; expires 30d;
#   }
#
# Deny all attempts to access PHP Files in the uploads directory
#   location ~* /(?:uploads|files)/.*\.php$ {
#     deny all;
#   }
