# modules/desktop/media/daw.nix
#
# I make games on my spare time (and occasionally edit audio for videos). These
# need music and sound effects. In the past, I've used Apple Logic, Fruityloops,
# and Adobe Audition. To replace them on Linux, I've replaced them with Ardour,
# LMMS, and Audacity, respectively with much success.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.media.daw;
in {
  options.modules.desktop.media.daw = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.variables = let
      makePluginPath = format:
        (makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ]) + ":$HOME/.config/${format}";
    in {
      DSSI_PATH   = makePluginPath "dssi";
      LADSPA_PATH = makePluginPath "ladspa";
      LV2_PATH    = makePluginPath "lv2";
      LXVST_PATH  = makePluginPath "lxvst";
      VST_PATH    = makePluginPath "vst";
      VST3_PATH   = makePluginPath "vst3";
    };

    services.pipewire.jack.enable = true;

    user.packages = with pkgs; [
      ardour      # My DAW for recording
      audacity    # For one-off audio editing
      sunvox      # For chiptune

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
