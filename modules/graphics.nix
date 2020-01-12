# It's difficult to be an artist/designer on Linux. I miss adobe and my tablets
# don't work without a lot of heart-ache. I set up a second computer just for
# adobe work (and gaming) to address this, so why do I install these programs on
# linux? Because sometimes I need to do some quick work right there and then.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    font-manager     # so many damned fonts...

    imagemagick      # for image manipulation from the shell
    aseprite-unfree  # pixel art
    inkscape         # illustrator & indesign
    krita            # replaces photoshop
    gimp             # replaces photoshop
    gimpPlugins.resynthesizer2  # content-aware scaling in gimp
  ];

  my.home.xdg.configFile = {
    "GIMP/2.10" = { source = <my/config/gimp>; recursive = true; };
  };
}
