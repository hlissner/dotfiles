# modules/apps/media/pdf.nix --- for managing PDFs
#
# TODO

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.media.pdf;
in {
  options.modules.apps.media.pdf = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      ghostscript    # for optimizing pdfs
      poppler-utils  # various pdf tools
      wkhtmltopdf
      pdfgrep
      img2pdf
      ocrmypdf
    ];
  };
}
