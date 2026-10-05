# modules/apps/supersonic.nix

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.apps.supersonic;
in {
  options.modules.apps.supersonic = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      supersonic
      playerctl      # MPRIS remote
      libsecret      # for subsonic.zsh
      (mkLauncherEntry "Rate current song ->" {
        description = "In ${config.modules.apps.browsers.default}";
        icon = "rating";
        exec = "hey @supersonic rate";
      })
    ];

    # Passwords go through org.freedesktop.secrets. There is no plaintext
    # fallback, only a login dialog every launch.
    modules.services.gnome-keyring.enable = true;

    modules.wm.theme.files.supersonic = {
      input_path  = "${config.hey.configDir}/supersonic/colors.template.toml";
      output_path = "${config.home.configDir}/supersonic/themes/noctalia.toml";
      # Exits non-zero when nothing is listening, which isn't a failure.
      post_hook = "${getExe pkgs.supersonic} -reload-theme 2>/dev/null || true";
    };
  };
}
