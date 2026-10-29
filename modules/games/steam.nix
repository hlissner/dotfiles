# modules/games/steam.nix

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.games.steam;
in {
  options.modules.games.steam = with types; {
    enable = mkBoolOpt false;
    libraryDir = mkOpt str "${config.home.dataDir}/Steam";
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

    # Ensure Steam opens in the workspace that it was launched from. Because of
    # the 5-10s startup time, I can't go anywhere else or Steam will follow me.
    home.dataFile."applications/steam.desktop" = mkIf (config.modules.wm.desktop == "niri") {
      source = let
        launch = pkgs.writeShellScript "steam-launch" ''
          ${config.hey.bin} wm launch -a '^(steam|gamescope|steam_app_(default|[0-9]+))$' -- steam "$@"
          # A second `steam` only pokes the running one and comes straight back;
          # the controller stays on until the real one is gone.
          ${pkgs.procps}/bin/pgrep -u "$UID" -x steam >/dev/null || ${config.hey.bin} .dev steam-controller off
        '';
      in pkgs.runCommand "steam.desktop" {} ''
        sed 's@^Exec=steam@Exec=${launch}@' \
          ${config.programs.steam.package}/share/applications/steam.desktop > $out
      '';
    };

    # Auto-delete the *.desktop files Steam generates. I will never launch my
    # games through them; Steam is my game launcher (and I don't want Rofi
    # picking them up).
    systemd.user = let
      dir = "${config.home.dataDir}/applications";
      sweep = pkgs.writeShellScript "steam-sweep-shortcuts" ''
        ${pkgs.gnugrep}/bin/grep -lZ '^Exec=steam steam://rungameid/' ${dir}/*.desktop 2>/dev/null \
          | ${pkgs.findutils}/bin/xargs -0 -r ${pkgs.coreutils}/bin/rm -f
      '';
    in {
      services.steam-sweep-shortcuts = {
        description = "Remove Steam's per-game .desktop shortcuts";
        wantedBy = [ "default.target" ];   # the path unit won't fire for what's already there
        serviceConfig = {
          Type = "oneshot";
          ExecStart = sweep;
        };
      };
      paths.steam-sweep-shortcuts = {
        wantedBy = [ "default.target" ];
        pathConfig.PathChanged = dir;
      };

      # Better for steam proton games
      settings.Manager.DefaultLimitNOFILE = mkDefault 1048576;
    };
  };
}
