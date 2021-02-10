# modules/shell/adl.nix
#
# To maintain my filty weeb habits, I need tools. Tools that make it easy to
# watch animu and track 'em on anilist. Laziness > my weebery.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.adl;
in {
  options.modules.shell.adl = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      # Dependencies
      my.trackma
      my.anime-downloader
      mpv

      # The star of the show
      my.adl
    ];
  };
}
