# modules/desktop/apps/steam.nix

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.desktop.apps.steam;
in {
  options.modules.desktop.apps.steam = with types; {
    enable = mkBoolOpt false;
    mangohud.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable {
    programs = {
      steam.enable = true;
      gamemode = {
        enable = true;
        settings = {
          general = {
            inhibit_screensaver = 0;
            renice = 10;
          };
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
          };
        };
      };
    };

    user.extraGroups = [ "gamemode" ];

    environment.systemPackages = with pkgs; [
      # Stop Steam from polluting $HOME
      (let pkg = config.programs.steam.package;
       in mkWrapper [
         pkg
         pkg.run   # for GOG and humble bundle games
       ] ''
         wrapProgram "$out/bin/steam" --run 'export HOME="$XDG_FAKE_HOME"'
         wrapProgram "$out/bin/steam-run" --run 'export HOME="$XDG_FAKE_HOME"'
       '')
    ] ++ (if cfg.mangohud.enable then [ pkgs.mangohud ] else []);

    # better for steam proton games
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
  };
}
