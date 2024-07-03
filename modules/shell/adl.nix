# modules/shell/adl.nix
#
# To maintain my filty weeb habits, I need tools. Tools that make it easy to
# watch animu and track 'em on anilist. Laziness > my weebery.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.adl;
in {
  options.modules.shell.adl = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # Dependencies
      trackma
      anime-downloader
      mpv

      # The star of the show
      adl
    ];
  };
}
