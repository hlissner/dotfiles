{ config, options, lib, pkgs, ... }:

with lib;
{
  imports = [
      # aquanaut = callPackage (import ./aquanaut {});
    ./fluorescence
  ];

  options.modules.theme = {
    name    = mkOption { type = with types; nullOr str; default = null; };
    version = mkOption { type = with types; nullOr str; default = null; };
    path = mkOption {
      type = with types; nullOr path;
      default = null;
    };

    wallpaper = {
      path = mkOption {
        type = with types; nullOr str;
        default = if config.modules.theme.path != null
                  then "${config.modules.theme.path}/wallpaper.png"
                  else null;
      };

      filter = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        options = mkOption {
          type = types.str;
          default = "-gaussian-blur 0x2 -modulate 70 -level 5%";
        };
      };
    };
  };

  config = mkIf (config.modules.theme.wallpaper.path != null &&
                 builtins.pathExists config.modules.theme.wallpaper.path) {
    my.home.home.file.".background-image".source =
      config.modules.theme.wallpaper.path;

    services.xserver.displayManager.lightdm.background =
      mkIf config.modules.theme.wallpaper.filter.enable
        (let filteredPath = "wallpaper.filtered.png";
             filteredWallpaper =
               with pkgs; runCommand "filterWallpaper"
                 { buildInputs = [ imagemagick ]; } ''
                     mkdir "$out"
                     convert ${config.modules.theme.wallpaper.filter.options} \
                       ${config.modules.theme.wallpaper.path} $out/${filteredPath}
                   '';
         in "${filteredWallpaper}/${filteredPath}");
  };
}
