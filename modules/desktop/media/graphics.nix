# modules/desktop/media/graphics.nix
#
# I use almost every app in the Adobe suite, both professionally and personally.
# Sacrificing them was the hardest (and most liberating) part of my switch to
# Linux more than a decade ago. For much of that time I've maintained a
# dedicated Windows PC for it, but within the past few years (2021/2022), its
# alternatives have finally (in my opinion) become viable enough for me to drop
# the second PC.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) configDir;
    cfg = config.modules.desktop.media.graphics;
in {
  options.modules.desktop.media.graphics = {
    enable         = mkBoolOpt false;
    tools.enable   = mkBoolOpt true;
    raster.enable  = mkBoolOpt true;
    vector.enable  = mkBoolOpt true;
    sprites.enable = mkBoolOpt true;
    design.enable  = mkBoolOpt true;
    print.enable   = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs.unstable;
      (if cfg.tools.enable then [
        font-manager   # for easily toggling and previewing groups of fonts
        imagemagick    # for CLI image manipulation
      ] else []) ++

      # Replaces Illustrator (maybe indesign?)
      (if cfg.vector.enable then [
        inkscape
      ] else []) ++

      # Replaces Photoshop
      (if cfg.raster.enable then [
        (gimp-with-plugins.override {
          plugins = with gimpPlugins; [
            bimp            # batch image manipulation
            # resynthesizer   # content-aware scaling in gimp
            gmic            # an assortment of extra filters
          ];
        })
      ] else []) ++

      # Sprite sheets & animation
      (if cfg.sprites.enable then [
        aseprite-unfree
      ] else []) ++

      # Replaces Adobe XD (or Sketch)
      (if cfg.design.enable then [
        figma-linux   # FIXME ew, electron
      ] else []) ++

      # Replaces InDesign
      (if cfg.print.enable then [
        scribus
        cyan          # CYMK converter/viewer
      ] else []);

    home.configFile = mkIf cfg.raster.enable {
      "GIMP/2.10" = { source = "${configDir}/gimp"; recursive = true; };
      # TODO Inkscape dotfiles
    };
  };
}
