# modules/desktop/apps/skype.nix --- oh god why
#
# Skype on Linux. I'm sure there's a card for this in cards against humanity.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.apps.skype;
in {
  options.modules.desktop.apps.skype = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs.unstable; [
      skypeforlinux
      skype_call_recorder
    ];
  };
}
