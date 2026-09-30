# modules/apps/media/daw.nix
#
# I make games on my spare time (and occasionally edit audio for videos). These
# need music and sound effects. In the past, I've used Apple Logic, Fruityloops,
# and Adobe Audition. To replace them on Linux, I use Reaper because it's the
# Blender of DAWs (scriptable, versatile, Linux-friendly, and no subscription
# pricing) and audacity for quick edits. I sometimes dip into Renoise too.

{ self, lib, config, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.media.daw;
    # Every plugin format I care to support
    formats = [ "dssi" "ladspa" "lv2" "lxvst" "vst" "vst3" ];
    pluginPaths = f:
      genAttrs' formats (format: nameValuePair "${toUpper format}_PATH" (f format));
in {
  options.modules.apps.media.daw = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment = {
      profileRelativeSessionVariables = pluginPaths (format: [ "/lib/${format}" ]);
      variables = pluginPaths (format: [ "$XDG_DATA_HOME/${format}" ]);
    };

    services.pipewire.jack.enable = true;

    user.packages = with pkgs; [
      reaper        # My DAW of choice
      audacity      # For one-off audio editing
    ];
  };
}
