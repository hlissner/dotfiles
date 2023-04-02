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
      ardour
      sunvox
      audacity

      # LMMS creates .lmmsrc.xml in $HOME on launch (see LMMS/lmms#5869).
      # Jailing it has the side-effect of rooting all file dialogs in the fake
      # home, but this is easily worked around by adding proper shortcuts.
      (mkWrapper lmms ''
        wrapProgram "$out/bin/lmms" \
          --run 'cfgdir="$XDG_CONFIG_HOME/lmms"' \
          --run 'mkdir -p "$cfgdir"' \
          --add-flags '-c "$cfgdir/rc.xml"'
      '')
    ];
  };
}
