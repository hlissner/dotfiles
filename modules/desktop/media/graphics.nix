# modules/desktop/media/graphics.nix
#
# I use almost every app in the Adobe suite, both professionally and personally.
# Sacrificing them was the hardest (and most liberating) part of my switch to
# Linux more than a decade ago. For much of that time I've maintained a
# dedicated Windows PC for it, but within the past few years (2021/2022), its
# alternatives have finally (in my opinion) become viable enough for me to drop
# the second PC.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.graphics;
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
    user.packages = with pkgs;
      # CLI/scripting tools
      (optionals cfg.tools.enable [
        imagemagick
        # Optimizers
        # LOSSLESS   LOSSY
        optipng      pngquant
        jpegoptim    libjpeg  # (jpegtran)
                     gifsicle
      ]) ++

      # Replaces Illustrator (maybe indesign?)
      (optionals cfg.vector.enable [
        unstable.inkscape
      ]) ++

      # Replaces Photoshop
      (optionals cfg.raster.enable [
        (unstable.gimp3-with-plugins.override {
          plugins = with unstable.gimp3Plugins; [
            # bimp            # batch image manipulation
            # resynthesizer   # content-aware scaling in gimp
            gmic            # an assortment of extra filters
          ];
        })
        unstable.krita   # But Krita is better for digital illustration
      ]) ++

      # Sprite sheets & animation
      (optionals cfg.sprites.enable [
        unstable.aseprite-unfree
      ]) ++

      # Replaces Adobe XD (or Sketch)
      (optionals cfg.design.enable [
        (if config.modules.desktop.type == "wayland"
         then figma-linux.overrideAttrs (final: prev: {
           postFixup = ''
             substituteInPlace $out/share/applications/figma-linux.desktop \
               --replace "Exec=/opt/figma-linux/figma-linux" \
                         "Exec=$out/bin/${final.pname} --enable-features=UseOzonePlatform \
                                                       --ozone-platform=wayland \
                                                       --enable-vulkan \
                                                       --enable-gpu-rasterization \
                                                       --enable-oop-rasterization \
                                                       --enable-gpu-compositing \
                                                       --enable-accelerated-2d-canvas \
                                                       --enable-zero-copy \
                                                       --canvas-oop-rasterization \
                                                       --disable-features=UseChromeOSDirectVideoDecoder \
                                                       --enable-accelerated-video-decode \
                                                       --enable-accelerated-video-encode \
                                                       --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,RawDraw,Vulkan \
                                                       --enable-hardware-overlays \
                                                       --enable-unsafe-webgpu"
           '';
         })
         else figma-linux)
      ]);

    home.configFile = mkIf cfg.raster.enable {
      "GIMP/2.10" = {
        source = "${hey.configDir}/gimp";
        recursive = true;
      };
      # TODO Inkscape dotfiles
    };
  };
}
