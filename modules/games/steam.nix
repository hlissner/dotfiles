# modules/games/steam.nix

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.games.steam;
in {
  options.modules.games.steam = with types; {
    enable = mkBoolOpt false;
    libraryDir = mkOpt str "";
  };

  config = mkIf cfg.enable {
    # Moves Windows thread-sync primitives into the kernel, cutting wineserver
    # overhead, improving 1% lows in CPU-heavy games/apps. Needs kernel 6.14+
    # and a Proton that uses it: GE-Proton enables it automatically when the
    # module is present; upstream Proton may still want PROTON_USE_NTSYNC=1 in
    # the game's launch options depending on version.
    boot.kernelModules = [ "ntsync" ];

    programs = {
      steam = {
        enable = true;
        package = mkIf config.modules.xdg.enable (pkgs.steam.override {
          # Obey XDG, damn it!
          extraProfile = ''export HOME="''${XDG_FAKE_HOME:-$HOME}"'';
        });
        remotePlay.openFirewall = true;
        # gamescopeSession.enable = true;
        extraPackages = with pkgs; [ gamescope mangohud ];
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      # Makes gamemoderun available, but it must be selectively enabled for
      # games by changing said game's launch options to 'gamemoderun %command%'.
      gamemode = {
        enable = true;
        settings = {
          general = {
            inhibit_screensaver = 0;
            renice = 10;
          };
          custom = {
            start = "${config.hey.bin} hook on-gamemode on";
            end = "${config.hey.bin} hook on-gamemode off";
          };
        };
      };

      # E.g. 'gamemoderun gamescope -f -W 2560 -H 1440 -r 144 -- %command%'
      # Helpful options:
      #   --adaptive-sync
      #   --force-grab-cursor
      #   --mangoapp
      #   --expose-wayland
      gamescope = {
        enable = true;
        capSysNice = false;
      };
    };

    user.extraGroups = [ "gamemode" ];

    # Better for steam proton games
    systemd.user.settings.Manager.DefaultLimitNOFILE = mkDefault 1048576;
  };
}
