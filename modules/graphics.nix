# modules/graphics.nix
#
# The hardest part about switching to linux? Sacrificing Adobe. It really is
# difficult to replace and its open source alternatives don't *quite* cut it,
# but enough that I can do a fraction of it on Linux. For the rest I have a
# second computer dedicated to design work (and gaming).

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
