# modules/desktop/media/pdf.nix --- for managing PDFs
#
# TODO

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.pdf;
in {
  options.modules.desktop.media.pdf = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs.unstable; [
      ghostscript    # for optimizing pdfs
      poppler-utils  # various pdf tools
      wkhtmltopdf
      pdfgrep
      img2pdf
      ocrmypdf
    ];
  };
}
