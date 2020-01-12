{ config, options, lib, pkgs, ... }:

with lib;
{
  options.theme = {
    wallpaper = mkOption {
      type = with types; nullOr (either str path);
      default = null;
      description = "The wallpaper to use";
    };

    # TODO Colors?
  };

  config = {
    # Set up wallpaper and blur/darken it for lock/login screen
    my.home.home.file.".background-image".source = config.theme.wallpaper;
    services.xserver.displayManager.lightdm.background =
      let blurredWallpaper =
            with pkgs; runCommand "blurWallpaper"
              { buildInputs = [ imagemagick ]; } ''
                mkdir "$out"
                convert -gaussian-blur 0x2 -modulate 70 -level 5% \
                  ${config.theme.wallpaper} $out/wallpaper.blurred.png
              '';
      in mkIf (config.theme.wallpaper != null)
        "${blurredWallpaper}/wallpaper.blurred.png";
  };
}
