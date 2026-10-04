# modules/apps/feishin.nix --- a Subsonic client with a GUI
#
# It's pretty, it's probably the nicest Navidrome client, but it's electron and
# god is it buggy. Sigh.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.feishin;
in {
  options.modules.apps.feishin = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      feishin
      playerctl      # MPRIS remote
    ];

    # Feishin auto-reloads when its themes are changed.
    modules.wm.theme.files.feishin = {
      input_path  = "${config.hey.configDir}/feishin/colors.template.json";
      output_path = "${config.home.configDir}/feishin/Themes/noctalia.json";
    };
  };
}
