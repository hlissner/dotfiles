{ lib, pkgs, ... }:

with builtins;
with lib;
{
  toCSSFile = file:
    let fileName = baseNameOf file;
        compiledStyles =
          pkgs.runCommand "compileScssFile"
            { buildInputs = [ sass ]; } ''
              mkdir "$out"
              scss --sourcekkmap=none \
                   --no-cache \
                   --style compressed \
                   --default-encoding utf-8 \
                   "${file}" \
                   >>"$out/${fileName}.css"
            '';
    in "${compiledStyles}/${fileName}";

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
