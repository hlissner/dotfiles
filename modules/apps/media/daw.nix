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

    user.packages = with pkgs; [
      # pipewire.jack.enable put pipewire's libjack on every process's
      # LD_LIBRARY_PATH; pw-jack does it for one. Reaper's JACK backend dlopens
      # libjack, so it's launched through it -- menu entry included, since its
      # Exec is a bare `reaper`.
      pipewire.jack   # pw-jack CMD, for the rest
      (symlinkJoin {
        name = "reaper-pw-jack";
        paths = [ reaper ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          rm $out/bin/reaper
          makeWrapper ${getExe' pipewire.jack "pw-jack"} $out/bin/reaper \
            --add-flags ${reaper}/bin/reaper
        '';
      })

      # REVIEW: audacity 4 fails to build (gcc 16); see NixOS/nixpkgs#572942
      # audacity      # For one-off audio editing
    ];
  };
}
