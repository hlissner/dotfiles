# modules/desktop/media/graphics.nix
#
# The hardest part about switching to linux? Sacrificing Adobe. It really is
# difficult to replace and its open source alternatives don't *quite* cut it,
# but enough that I can do a fraction of it on Linux. For the rest I have a
# second computer dedicated to design work (and gaming).

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
        gimp
        gimpPlugins.resynthesizer  # content-aware scaling in gimp
        gimpPlugins.gmic           # an assortment of extra filters
        gimpPlugins.bimp           # batch image manipulation
      ] else []) ++

      # Sprite sheets & animation
      (if cfg.sprites.enable then [
        aseprite-unfree
      ] else []) ++

      # Replaces Adobe XD/InDesign (or Sketch)
      (if cfg.design.enable then [
        figma-linux   # FIXME ew, electron
      ] else []);

    home.configFile = mkIf cfg.raster.enable {
      "GIMP/2.10" = { source = "${configDir}/gimp"; recursive = true; };
      # TODO Inkscape dotfiles
    };
  };
}
