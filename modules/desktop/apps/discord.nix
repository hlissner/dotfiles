{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.discord;
in {
  options.modules.desktop.apps.discord = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.unstable.vesktop;
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = {
      DISCORD_DISABLE_TRACKING = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    user.packages = [ cfg.package ];

    home.configFile."vesktop/settings/settings.json".text = builtins.toJSON {
      arRPC = true;
      checkUpdates = false;
      discordBranch = "stable";
      minimizeToTray = false;
      openLinksWithElectron = false;
      staticTitle = true;
      hardwareAcceleration = true;
    };
  };
}
