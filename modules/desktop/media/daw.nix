# modules/desktop/media/daw.nix
#
# I make games on my spare time (and occasionally edit audio for videos). These
# need music and sound effects. In the past, I've used Apple Logic, Fruityloops,
# and Adobe Audition. To replace them on Linux, I use Reaper.

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
      reaper        # My DAW for making/recording music
      # audacity    # For one-off audio editing
      # sunvox      # For chiptune
    ];
  };
}
