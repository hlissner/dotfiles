# modules/desktop/media/daw.nix
#
# I make music for my games. LMMS+Ardour is my DAW. When I'm in the mood for a
# quicky I fire up sunvox instead. It runs absolutely anywhere, even on my ipad
# and phone -- as if I'd ever need to.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.media.daw;
in {
  options.modules.desktop.media.daw = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.pipewire.jack.enable = true;

    user.packages = with pkgs.unstable; [
      ardour     # recording, mixing, loops
      lmms       # for making music
      sunvox     # my favorite midi tracker
      audacity   # for recording and remastering audio
    ];
  };
}
