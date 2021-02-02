{ lib, pkgs, ... }:

with builtins;
with lib;
{
  toCSSFile = file:
    let fileName = removeSuffix ".scss" (baseNameOf file);
        compiledStyles =
          pkgs.runCommand "compileScssFile"
            { buildInputs = [ pkgs.sass ]; } ''
              mkdir "$out"
              scss --sourcemap=none \
                   --no-cache \
                   --style compressed \
                   --default-encoding utf-8 \
                   "${file}" \
                   >>"$out/${fileName}.css"
            '';
    in "${compiledStyles}/${fileName}.css";

  toFilteredImage = imageFile: options:
    let result = "result.png";
        filteredImage =
          pkgs.runCommand "filterWallpaper"
            { buildInputs = [ pkgs.imagemagick ]; } ''
              mkdir "$out"
              convert ${options} ${imageFile} $out/${result}
            '';
    in "${filteredImage}/${result}";
}
