# modules/desktop/apps/spotify.nix --- TODO
#
# I use spotify for my music needs. Gone are the days where I'd manage 200gb+ of
# local music; most of which I haven't heard or don't even like.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.spotify;
    spicetify = pkgs.unstable.spicetify-cli;
in {
  imports = [
    hey.modules.spicetify-nix.default
  ];

  options.modules.desktop.apps.spotify = with types; {
    enable = mkBoolOpt false;
    theme = mkOpt str "";
    colorscheme = mkOpt str "";
  };

  config = mkIf cfg.enable {
    programs.spicetify.enable = true;

    user.packages = with pkgs; [
      playerctl   # To control it remotely.
    ];
  };
}
