# modules/graphics.nix
#
# The hardest part about switching to linux was sacrifices adobe. It is so bad I
# have a second computer dedicated to adobe (and gaming). Still, I can still
# manage half of my design work on open source alternatives.

{ config, lib, pkgs, ... }:
{
  my = {
    packages = with pkgs; [
      font-manager     # so many damned fonts...

      imagemagick      # for image manipulation from the shell
      aseprite-unfree  # pixel art
      inkscape         # illustrator & indesign
      krita            # replaces photoshop
      gimp             # replaces photoshop
      gimpPlugins.resynthesizer2  # content-aware scaling in gimp
    ];

    home.xdg.configFile = {
      "GIMP/2.10" = { source = <config/gimp>; recursive = true; };
    };
  };
}
