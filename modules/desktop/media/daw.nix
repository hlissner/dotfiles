# modules/desktop/media/daw.nix
#
# I make music for my games. LMMS is my DAW; or will be, once I've weened myself
# off of Fruityloops. When I'm in the mood for a quicky I fire up sunvox
# instead. It runs absolutely anywhere, even on my ipad and phone. As if I'd
# ever need to.

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.media.daw;
in {
  options.modules.desktop.media.daw = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      unstable.ardour  # recording, mixing, loops
      lmms             # for making music
      unstable.sunvox  # my favorite midi tracker
      # audacity   # for recording and remastering audio
    ];
  };
}
